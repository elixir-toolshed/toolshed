defmodule Toolshed.Tping do
  @moduledoc """
  This module provides the `tping` command
  """

  require Record

  @doc false
  Record.defrecordp(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  @doc """
  Check if a computer is up using TCP.

  Options:

  * `:ifname` - Specify a network interface to use. (e.g., "eth0")
  * `:port` - Which TCP port to try (defaults to 80)

  ## Examples

      iex> tping "nerves-project.org"
      Response from nerves-project.org (185.199.108.153:80): time=4.155ms

      iex> tping "192.168.1.1"
      Response from 192.168.1.1 (192.168.1.1:80): time=1.227ms
  """
  @spec tping(String.t(), keyword()) :: :"do not show this result in output"
  def tping(address, options \\ []) do
    case resolve_addr(address) do
      {:ok, ip} ->
        port = Keyword.get(options, :port, 80)
        ping_ip(address, ip, port, connect_options(options))

      {:error, message} ->
        IO.puts(message)
    end

    IEx.dont_display_result()
  end

  defp connect_options(ping_options) do
    Enum.flat_map(ping_options, &ping_option_to_connect/1)
  end

  defp ping_option_to_connect({:ifname, ifname}) do
    ifname_cl = to_charlist(ifname)

    with {:ok, ifaddrs} <- :inet.getifaddrs(),
         {_, params} <- Enum.find(ifaddrs, fn {k, _v} -> k == ifname_cl end),
         addr when is_tuple(addr) <- Keyword.get(params, :addr) do
      [{:ip, addr}]
    else
      _ ->
        # HACK: Give an IP address that will give an address error so
        # that if the interface appears that it will work.
        [{:ip, {1, 2, 3, 4}}]
    end
  end

  defp ping_option_to_connect({_option, _}), do: []

  defp ping_ip(address, ip, port, connect_options) do
    message =
      case try_connect(ip, port, connect_options) do
        {:ok, micros} ->
          "Response from #{address} (#{pretty_ip_port(ip, port)}): time=#{micros / 1000}ms"

        {:error, reason} ->
          "#{address} (#{pretty_ip_port(ip, port)}): #{inspect(reason)}"
      end

    IO.puts(message)
  end

  defp pretty_ip_port({_, _, _, _} = ip, port), do: "#{:inet.ntoa(ip)}:#{port}"
  defp pretty_ip_port(ip, port), do: "[#{:inet.ntoa(ip)}]:#{port}"

  defp resolve_addr(address) do
    case gethostbyname(address, :inet) || gethostbyname(address, :inet6) do
      nil -> {:error, "Error resolving #{address}"}
      ip -> {:ok, ip}
    end
  end

  defp gethostbyname(address, family) do
    case :inet.gethostbyname(to_charlist(address), family) do
      {:ok, hostent} ->
        hostent(h_addr_list: ip_list) = hostent
        hd(ip_list)

      _ ->
        nil
    end
  end

  defp try_connect(address, port, connect_options) do
    start = System.monotonic_time(:microsecond)

    case :gen_tcp.connect(address, port, connect_options) do
      {:ok, pid} ->
        :gen_tcp.close(pid)
        {:ok, System.monotonic_time(:microsecond) - start}

      {:error, :econnrefused} ->
        # If the connection is refused, the machine is up.
        {:ok, System.monotonic_time(:microsecond) - start}

      error ->
        error
    end
  end
end
