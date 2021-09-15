defmodule Toolshed.TCPPing do
  @moduledoc """
  Utility for pinging a remote host using TCP
  """

  require Record

  @doc false
  Record.defrecord(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  @doc """
  Check if a computer is up using TCP.

  Options:

  * `:ifname` - Specify a network interface to use. (e.g., "eth0")

  ## Examples

      iex> tping "nerves-project.org"
      Response from nerves-project.org (185.199.108.153): time=4.155ms

      iex> tping "192.168.1.1"
      Response from 192.168.1.1 (192.168.1.1): time=1.227ms
  """
  @spec tping(String.t()) :: :"do not show this result in output"
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

  @doc """
  Ping an IP address using TCP

  This tries to connect to the remote host using TCP instead of sending an ICMP
  echo request like normal ping. This made it possible to write in pure Elixir.

  NOTE: Specifying an `:ifname` only sets the source IP address for the TCP
  connection. This is only a hint to use the specified interface and not a
  guarantee. For example, if you have two interfaces on the same LAN, the OS
  routing tables may send traffic out one interface in preference to the one
  that you want. On Linux, you can enable policy-based routing and add source
  routes to guarantee that packets go out the desired interface.

  Options:

  * `:ifname` - Specify a network interface to use. (e.g., "eth0")
  * `:port` - Which TCP port to try (defaults to 80)

  ## Examples

      iex> ping "nerves-project.org"
      Press enter to stop
      Response from nerves-project.org (185.199.108.153): time=4.155ms
      Response from nerves-project.org (185.199.108.153): time=10.385ms
      Response from nerves-project.org (185.199.108.153): time=12.458ms

      iex> ping "google.com", ifname: "wlp5s0"
      Press enter to stop
      Response from google.com (172.217.7.206): time=88.602ms
  """
  @spec ping(String.t(), keyword()) :: :"do not show this result in output"
  def ping(address, options \\ []) do
    IO.puts("Press enter to stop")

    pid = spawn(fn -> repeat_ping(address, options) end)
    _ = IO.gets("")
    Process.exit(pid, :kill)

    IEx.dont_display_result()
  end

  defp repeat_ping(address, options) do
    tping(address, options)
    Process.sleep(1000)
    repeat_ping(address, options)
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
          "Response from #{address} (#{:inet.ntoa(ip)}): time=#{micros / 1000}ms"

        {:error, reason} ->
          "#{address} (#{:inet.ntoa(ip)}): #{inspect(reason)}"
      end

    IO.puts(message)
  end

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
