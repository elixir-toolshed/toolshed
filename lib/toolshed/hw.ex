defmodule Toolshed.HW do
  @moduledoc """
  Helpers that are useful for querying hardware information. These are Linux/Nerves-specific.

  Helpers include:

   * `lsusb/0`   - print out connected USB devices
   * `cpu/0`     - print out cpu utilization
  """

  @doc """
  Print out information on all of the connected USB devices.
  """
  @spec lsusb() :: :"do not show this result in output"
  def lsusb() do
    Enum.each(Path.wildcard("/sys/bus/usb/devices/*/uevent"), &print_usb/1)
    IEx.dont_display_result()
  end

  @doc """
  Print out CPU utilization
  """
  def cpu do
    with {:ok, values} <- get_info() do
      ~w(load_1_min load_5_min load_15_min running_tasks last_pid)
      |> Enum.zip(values)
      |> Enum.map(fn {key, val} -> key <> ": " <> val end)
      |> Enum.join(", ")
    else
      {:error, _} -> "Opps... OS not supported"
    end
  end

  defp get_info do
    with {:ok, res} <- File.read("/proc/loadavg") do
      {:ok, String.split(res)}
    else
      _ -> {:error, :os_not_supported}
    end
  end

  defp print_usb(uevent_path) do
    File.read!(uevent_path)
    |> parse_kv_config()
    |> find_more_usb_info(Path.dirname(uevent_path))
    |> print_usb_info()
  end

  defp print_usb_info(%{"DEVTYPE" => "usb_device"} = info) do
    vidpid = to_vidpid(info["PRODUCT"])

    IO.puts(
      "Bus #{info["BUSNUM"]} Device #{info["DEVNUM"]}: ID #{vidpid} #{info["manufacturer"]} #{
        info["product"]
      }"
    )
  end

  defp print_usb_info(_info), do: :ok

  defp to_vidpid(""), do: "?"

  defp to_vidpid(raw) do
    # The VIDPID comes in as "vid/pid/somethingelse"
    [vid_str, pid_str, _] = String.split(raw, "/", trim: true)
    vid = String.pad_leading(vid_str, 4, "0")
    pid = String.pad_leading(pid_str, 4, "0")
    vid <> ":" <> pid
  end

  defp parse_kv_config(contents) do
    contents
    |> String.split("\n")
    |> Enum.flat_map(&parse_kv/1)
    |> Enum.into(%{})
  end

  defp parse_kv(""), do: []
  defp parse_kv(<<"#", _rest::binary>>), do: []

  defp parse_kv(key_equals_value) do
    [key, value] = String.split(key_equals_value, "=", parts: 2, trim: true)
    [{key, value}]
  end

  defp find_more_usb_info(info, sysfs_path) do
    with {:ok, manufacturer} <- File.read(Path.join(sysfs_path, "manufacturer")),
         {:ok, product} <- File.read(Path.join(sysfs_path, "product")) do
      info
      |> Map.put("manufacturer", String.trim(manufacturer))
      |> Map.put("product", String.trim(product))
    else
      _ -> info
    end
  end
end
