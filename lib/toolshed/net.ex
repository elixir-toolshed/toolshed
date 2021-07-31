defmodule Toolshed.Net do
  @moduledoc """
  Network related helpers
  """

  require Record

  @otp_version :erlang.system_info(:otp_release)
               |> to_string()
               |> String.to_integer()

  @doc false
  Record.defrecord(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  @doc """
  Return the hostname

  ## Examples

      iex> hostname
      "nerves-1234"
  """
  @spec hostname() :: String.t()
  def hostname() do
    {:ok, hostname_charlist} = :inet.gethostname()
    to_string(hostname_charlist)
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
    IO.puts("Name:     #{name}")
    name_charlist = to_charlist(name)

    with {:ok, v4} <- :inet.gethostbyname(name_charlist, :inet) do
      print_addresses(v4)
    else
      {:error, :nxdomain} -> IO.puts("IPv4 lookup failed")
    end

    with {:ok, v6} <- :inet.gethostbyname(name_charlist, :inet6) do
      print_addresses(v6)
    else
      {:error, :nxdomain} -> IO.puts("IPv6 lookup failed")
    end

    IEx.dont_display_result()
  end

  defp print_addresses(hostent) do
    hostent(h_addr_list: ip_list) = hostent
    Enum.each(ip_list, &IO.puts("Address:  #{:inet.ntoa(&1)}"))
  end

  @doc """
  Check if a computer is up using ICMP.

  Options:

  * `:ifname`  - Specify a network interface to use. (e.g., "eth0")
  * `:timeout` - Specify the time in seconds to wait for a host to respond.

  ## Examples

      iex> tping "nerves-project.org"
      Response from nerves-project.org (185.199.108.153): time=4.155ms

      iex> tping "192.168.1.1"
      Response from 192.168.1.1 (192.168.1.1): time=1.227ms
  """
  @spec tping(String.t()) :: :"do not show this result in output"
  def tping(address, options \\ []) do
    single_ping(address, options, 1)

    IEx.dont_display_result()
  end

  @doc """
  Ping an IP address using ICMP.

  NOTE: Specifying an `:ifname` only sets the source IP address for the
  connection. This is only a hint to use the specified interface and not a
  guarantee. For example, if you have two interfaces on the same LAN, the OS
  routing tables may send traffic out one interface in preference to the one
  that you want. On Linux, you can enable policy-based routing and add source
  routes to guarantee that packets go out the desired interface.

  Options:

  * `:ifname`  - Specify a network interface to use. (e.g., "eth0")
  * `:timeout` - Specify the time in seconds to wait for a host to respond.

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

  defp single_ping(address, options, sequence_number) do
    case resolve_addr(address) do
      {:ok, ip} ->
        ping_ip(address, ip, connect_options(options), sequence_number)

      {:error, message} ->
        IO.puts(message)
    end
  end

  defp repeat_ping(address, options, sequence_number \\ 1) do
    single_ping(address, options, sequence_number)
    Process.sleep(1000)
    repeat_ping(address, options, sequence_number + 1)
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

  defp ping_option_to_connect({:timeout, timeout}) do
    [{:timeout, round(timeout * 1000)}]
  end

  defp ping_option_to_connect({option, _}) do
    raise "Unknown option #{inspect(option)}"
  end

  defp ping_ip(address, ip, connect_options, sequence_number) do
    message =
      case try_connect(ip, connect_options, sequence_number) do
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

  defp try_connect(address, connect_options, sequence_number) do
    interface_address = Keyword.get(connect_options, :ip, :any)
    timeout = Keyword.get(connect_options, :timeout, 10_000)

    {family, protocol, request_packet_type, reply_packet_type} =
      case tuple_size(address) do
        4 -> {:inet, :icmp, 0x08, 0x00}
        8 -> {:inet6, {:raw, 58}, 0x80, 0x81}
      end

    packet = <<
      # Type (Echo request)
      request_packet_type::size(8),
      # Code
      0x00::size(8),
      # Checksum
      0x0000::big-integer-size(16),
      # Identifier
      0x0001::big-integer-size(16),
      # Sequence Number
      sequence_number::big-integer-size(16),
      # Payload
      "abcdefghijklmnopqrstuvwxyz012345"::binary
    >>

    with {:ok, socket} <- :socket.open(family, :dgram, protocol),
         :ok <- bind(socket, interface_address),
         start <- System.monotonic_time(:microsecond),
         :ok <- :socket.sendto(socket, packet, %{family: family, port: 0, addr: address}),
         {:ok, {_, reply_bytes}} <- :socket.recvfrom(socket, [], timeout),
         :ok <- check_ping_reply_byte_size(reply_bytes),
         :ok <- check_ping_reply_type(reply_bytes, reply_packet_type),
         {:ok, reply} <- parse_ping_reply(reply_bytes, reply_packet_type),
         :ok <- check_ping_reply_sequence_number(reply, sequence_number) do
      elapsed_time = System.monotonic_time(:microsecond) - start
      {:ok, elapsed_time}
    else
      error -> error
    end
  end

  # OTP 24 changed the return value from `:socket.bind`. This needs to be
  # accounted for at compile time or else dialyzer will raise an error for
  # the branch that will never match the code required for backwards
  # compatibility.
  if @otp_version >= 24 do
    defp bind(socket, interface_address) do
      addr = make_bind_addr(interface_address)

      case :socket.bind(socket, addr) do
        :ok -> :ok
        error -> error
      end
    end
  else
    defp bind(socket, interface_address) do
      addr = make_bind_addr(interface_address)

      case :socket.bind(socket, addr) do
        {:ok, _port} -> :ok
        error -> error
      end
    end
  end

  defp make_bind_addr(:any), do: :any

  defp make_bind_addr(interface_address) do
    family =
      case tuple_size(interface_address) do
        4 -> :inet
        8 -> :inet6
      end

    %{
      addr: interface_address,
      family: family,
      port: 0
    }
  end

  defp check_ping_reply_byte_size(reply_bytes) do
    case byte_size(reply_bytes) do
      40 -> :ok
      _ -> {:error, :unexpected_reply}
    end
  end

  defp check_ping_reply_type(reply_bytes, reply_packet_type) do
    case String.at(reply_bytes, 0) do
      <<^reply_packet_type>> -> :ok
      packet_type -> {:error, {:unexpected_reply_type, packet_type}}
    end
  end

  defp check_ping_reply_sequence_number(reply, expected_sequence_number) do
    case reply.sequence_number do
      ^expected_sequence_number -> :ok
      _ -> {:error, :unexpected_reply_sequence_nubmer}
    end
  end

  defp parse_ping_reply(reply_bytes, reply_packet_type) do
    <<
      # Type (Echo reply)
      ^reply_packet_type::size(8),
      # Code
      0x00::size(8),
      checksum::big-integer-size(16),
      identifier::big-integer-size(16),
      sequence_number::big-integer-size(16),
      payload::binary
    >> = reply_bytes

    {:ok,
     %{
       type: reply_packet_type,
       checksum: checksum,
       identifier: identifier,
       sequence_number: sequence_number,
       payload: payload
     }}
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
      "    inet #{:inet.ntoa(addr)}  netmask #{:inet.ntoa(netmask)}  broadcast #{:inet.ntoa(broadaddr)}"
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
