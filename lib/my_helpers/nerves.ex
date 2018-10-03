target = System.get_env("MIX_TARGET")

if target != nil and target != "host" do
  defmodule MyHelpers.Nerves do
    @moduledoc """
    Helpers that are useful on Nerves devices

    Helpers include:

     * `dmesg/0`   - print kernel messages
     * `reboot/0`  - reboots gracefully
     * `reboot!/0` - reboots immediately
    """

    defmacro __using__(_) do
      quote do
        import MyHelpers.Nerves
      end
    end

    @doc """
    Print out kernel log messages
    """
    @spec dmesg() :: :"do not show this result in output"
    def dmesg() do
      MyHelpers.cmd("dmesg")
      IEx.dont_display_result()
    end

    @doc """
    Shortcut to reboot a board. This is a graceful reboot, so it takes some time
    before the real reboot.
    """
    @spec reboot() :: no_return()
    defdelegate reboot(), to: Nerves.Runtime

    @doc """
    Remote immediately without a graceful shutdown. This is for the impatient.
    """
    @spec reboot!() :: no_return()
    def reboot!() do
      :erlang.halt()
    end

    @doc """
    Validate a firmware image

    All official Nerves Systems automatically validate newly installed firmware.
    For some systems, it's possible to disable this so that new firmware gets
    one chance to boot. If it's not "validated" before a reboot, then the device
    reverts to the old firmware.
    """
    @spec fw_validate() :: :ok | {:error, String.t()}
    def fw_validate() do
      case System.cmd("fw_setenv", ["nerves_fw_validated", "1"]) do
        {_, 0} -> :ok
        {output, _} -> {:error, output}
      end
    end

    @doc """
    Print out information on all of the connected USB devices.
    """
    @spec lsusb() :: :"do not show this result in output"
    def lsusb() do
      Enum.each(Path.wildcard("/sys/bus/usb/devices/*/uevent"), &print_usb/1)
      IEx.dont_display_result()
    end

    defp print_usb(uevent_path) do
      File.read!(uevent_path)
      |> parse_kv_config()
      |> print_usb_info()
    end

    defp print_usb_info(%{"DEVTYPE" => "usb_device"} = info) do
      IO.puts("Bus #{info["BUSNUM"]} Device #{info["DEVNUM"]}: ID #{info["PRODUCT"]}")
    end

    defp print_usb_info(_info), do: :ok

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
  end
else
  defmodule MyHelpers.Nerves do
    defmacro __using__(_) do
      # Skip if not running on Nerves
    end
  end
end
