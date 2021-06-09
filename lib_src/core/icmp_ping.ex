defmodule Toolshed.Core.ICMPPing do
  @otp_version :erlang.system_info(:otp_release)
               |> to_string()
               |> String.to_integer()

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

      iex> icmp_ping "nerves-project.org"
      Press enter to stop
      Response from nerves-project.org (185.199.108.153): time=4.155ms
      Response from nerves-project.org (185.199.108.153): time=10.385ms
      Response from nerves-project.org (185.199.108.153): time=12.458ms

      iex> icmp_ping "google.com", ifname: "wlp5s0"
      Press enter to stop
      Response from google.com (172.217.7.206): time=88.602ms
  """
  @spec icmp_ping(String.t(), keyword()) :: :"do not show this result in output"
  def icmp_ping(address, options \\ []) do
    IO.puts("Press enter to stop")

    pid = spawn(fn -> repeat_icmp_ping(address, options, 1) end)
    _ = IO.gets("")
    Process.exit(pid, :kill)

    IEx.dont_display_result()
  end

  defp single_icmp_ping(address, options, sequence_number) do
    case icmp_resolve_addr(address) do
      {:ok, ip} ->
        icmp_ping_ip(address, ip, icmp_connect_options(options), sequence_number)

      {:error, message} ->
        IO.puts(message)
    end
  end

  defp repeat_icmp_ping(address, options, sequence_number) do
    single_icmp_ping(address, options, sequence_number)
    Process.sleep(1000)
    repeat_icmp_ping(address, options, sequence_number + 1)
  end

  defp icmp_connect_options(ping_options) do
    Enum.flat_map(ping_options, &icmp_ping_option_to_connect/1)
  end

  defp icmp_ping_option_to_connect({:ifname, ifname}) do
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

  defp icmp_ping_option_to_connect({:timeout, timeout}) do
    [{:timeout, round(timeout * 1000)}]
  end

  defp icmp_ping_option_to_connect({option, _}) do
    raise "Unknown option #{inspect(option)}"
  end

  defp icmp_ping_ip(address, ip, connect_options, sequence_number) do
    message =
      case try_icmp_connect(ip, connect_options, sequence_number) do
        {:ok, micros} ->
          "Response from #{address} (#{:inet.ntoa(ip)}): time=#{micros / 1000}ms"

        {:error, reason} ->
          "#{address} (#{:inet.ntoa(ip)}): #{inspect(reason)}"
      end

    IO.puts(message)
  end

  defp icmp_resolve_addr(address) do
    case icmp_gethostbyname(address, :inet) || icmp_gethostbyname(address, :inet6) do
      nil -> {:error, "Error resolving #{address}"}
      ip -> {:ok, ip}
    end
  end

  defp icmp_gethostbyname(address, family) do
    case :inet.gethostbyname(to_charlist(address), family) do
      {:ok, hostent} ->
        hostent(h_addr_list: ip_list) = hostent
        hd(ip_list)

      _ ->
        nil
    end
  end

  defp try_icmp_connect(address, connect_options, sequence_number) do
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
         :ok <- icmp_bind(socket, interface_address),
         start <- System.monotonic_time(:microsecond),
         :ok <- :socket.sendto(socket, packet, %{family: family, port: 0, addr: address}),
         {:ok, {_, reply_bytes}} <- :socket.recvfrom(socket, [], timeout),
         :ok <- check_icmp_ping_reply_byte_size(reply_bytes),
         :ok <- check_icmp_ping_reply_type(reply_bytes, reply_packet_type),
         {:ok, reply} <- parse_icmp_ping_reply(reply_bytes, reply_packet_type),
         :ok <- check_icmp_ping_reply_sequence_number(reply, sequence_number) do
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
    defp icmp_bind(socket, interface_address) do
      addr = make_icmp_bind_addr(interface_address)

      case :socket.bind(socket, addr) do
        :ok -> :ok
        error -> error
      end
    end
  else
    defp icmp_bind(socket, interface_address) do
      addr = make_icmp_bind_addr(interface_address)

      case :socket.bind(socket, addr) do
        {:ok, _port} -> :ok
        error -> error
      end
    end
  end

  defp make_icmp_bind_addr(:any), do: :any

  defp make_icmp_bind_addr(interface_address) do
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

  defp check_icmp_ping_reply_byte_size(reply_bytes) do
    case byte_size(reply_bytes) do
      40 -> :ok
      _ -> {:error, :unexpected_reply}
    end
  end

  defp check_icmp_ping_reply_type(reply_bytes, reply_packet_type) do
    case String.at(reply_bytes, 0) do
      <<^reply_packet_type>> -> :ok
      packet_type -> {:error, {:unexpected_reply_type, packet_type}}
    end
  end

  defp check_icmp_ping_reply_sequence_number(reply, expected_sequence_number) do
    case reply.sequence_number do
      ^expected_sequence_number -> :ok
      _ -> {:error, :unexpected_reply_sequence_nubmer}
    end
  end

  defp parse_icmp_ping_reply(reply_bytes, reply_packet_type) do
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
end
