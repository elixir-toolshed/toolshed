defmodule Toolshed.Net do
  @moduledoc """
  Network related helpers
  """

  require Record

  alias Toolshed.Result

  @doc false
  Record.defrecord(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  @doc """
  Return the hostname

  ## Examples

      iex> hostname
      "nerves-1234"
  """
  @spec hostname() :: Result.t()
  def hostname() do
    {:ok, hostname_charlist} = :inet.gethostname()
    Result.new(to_string(hostname_charlist))
  end

  @doc """
  Lookup the specified hostname in the DNS and print out the addresses.

  ## Examples

      iex> nslookup "google.com"
      Name:     google.com
      Address:  172.217.7.238
      Address:  2607:f8b0:4004:804::200e
  """
  @spec nslookup(String.t()) :: :"do not show this result in output"
  def nslookup(name) do
    name_charlist = to_charlist(name)

    [
      "Name:     ",
      name,
      "\n",
      format_addresses(name_charlist, :inet),
      format_addresses(name_charlist, :inet6)
    ]
    |> Result.new()
  end

  defp format_addresses(name_charlist, family) do
    with {:ok, hostent} <- :inet.gethostbyname(name_charlist, family) do
      hostent(h_addr_list: ip_list) = hostent
      Enum.map(ip_list, fn ip -> ["Address:  ", :inet.ntoa(ip), "\n"] end)
    else
      {:error, :nxdomain} -> [family_name(family), " lookup failed\n"]
    end
  end

  defp family_name(:inet), do: "IPv4"
  defp family_name(:inet6), do: "IPv6"

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
        ping_ip(address, ip, connect_options(options))

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

  ## Examples

      iex> ping "nerves-project.org"
      Press enter to stop
      Response from nerves-project.org (185.199.108.153): time=4.155ms
      Response from nerves-project.org (185.199.108.153): time=10.385ms
      Response from nerves-project.org (185.199.108.153): time=12.458ms

      iex> Toolshed.Net.ping "google.com", ifname: "wlp5s0"
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

  defp ping_option_to_connect({option, _}) do
    raise "Unknown option #{inspect(option)}"
  end

  defp ping_ip(address, ip, connect_options) do
    message =
      case try_connect(ip, 80, connect_options) do
        {:ok, micros} ->
          "Response from #{address} (#{:inet.ntoa(ip)}): time=#{micros / 1000}ms"

        {:error, reason} ->
          "#{address} (#{:inet.ntoa(ip)}): #{inspect(reason)}"
      end

    IO.puts(message)
  end

  defp resolve_addr(address) do
    with {:ok, hostent} <- :inet.gethostbyname(to_charlist(address)),
         hostent(h_addr_list: ip_list) = hostent,
         first_ip = hd(ip_list) do
      {:ok, first_ip}
    else
      _ -> {:error, "Error resolving #{address}"}
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

  @doc """
  Print out the network interfaces and their addresses.
  """
  @spec ifconfig() :: :"do not show this result in output"
  def ifconfig() do
    {:ok, if_list} = :inet.getifaddrs()
    Enum.each(if_list, &print_if/1)
    IEx.dont_display_result()
  end

  defp print_if({ifname, kvlist}) do
    IO.puts("#{ifname}: flags=#{inspect(Keyword.get(kvlist, :flags))}")
    print_if_info(kvlist)
    IO.puts("")
  end

  defp print_if_info([]), do: :ok

  defp print_if_info([{:hwaddr, addr} | rest]) do
    string_address =
      addr
      |> Enum.map(&:io_lib.format("~2.16.0b", [&1]))
      |> Enum.join(":")

    :io.format('    hwaddr ~s~n', [string_address])
    print_if_info(rest)
  end

  defp print_if_info([{:addr, addr}, {:netmask, netmask}, {:broadaddr, broadaddr} | rest]) do
    IO.puts(
      "    inet #{:inet.ntoa(addr)}  netmask #{:inet.ntoa(netmask)}  broadcast #{
        :inet.ntoa(broadaddr)
      }"
    )

    print_if_info(rest)
  end

  defp print_if_info([{:addr, addr}, {:netmask, netmask} | rest]) do
    IO.puts("    inet #{:inet.ntoa(addr)}  netmask #{:inet.ntoa(netmask)}")
    print_if_info(rest)
  end

  defp print_if_info([_something_else | rest]) do
    print_if_info(rest)
  end
end
