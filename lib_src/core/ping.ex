defmodule Toolshed.Core.Ping do
  import Bitwise

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

  * `:count` - number of pings to send (defaults to 3)
  * `:identifier` - the identifier to use in the ICMP packets (default is to generate one)
  * `:ifname`  - network interface to use (e.g., "eth0")
  * `:timeout` - time in seconds to wait for a host to respond (defaults to 10 seconds)

  ## Examples

  ```
  iex> ping "nerves-project.org"
  Response from nerves-project.org (185.199.108.153): icmp_seq=0 time=14.908ms
  Response from nerves-project.org (185.199.108.153): icmp_seq=1 time=9.057ms
  Response from nerves-project.org (185.199.108.153): icmp_seq=2 time=21.099ms

  iex> ping "google.com", ifname: "wlp5s0"
  Response from google.com (172.217.7.206): icmp_seq=0 time=88.602ms
  ```
  """
  @spec ping(String.t(), keyword()) :: :"do not show this result in output"
  def ping(address, options \\ []) do
    options = Keyword.put_new_lazy(options, :identifier, fn -> :rand.uniform(65535) end)
    count = options[:count] || 3

    run_or_enter(fn ->
      repeat_icmp_ping(address, options, 0, count)
    end)

    IEx.dont_display_result()
  end

  defp repeat_icmp_ping(_address, _options, count, max_count)
       when count >= max_count,
       do: :ok

  defp repeat_icmp_ping(address, options, count, max_count) do
    if count > 0, do: Process.sleep(1000)

    case gethostbyname(address, :inet) do
      nil -> "Error resolving #{address}"
      ip -> icmp_ping_ip(address, ip, options, count)
    end
    |> IO.puts()

    repeat_icmp_ping(address, options, count + 1, max_count)
  end

  defp icmp_ping_ip(address, ip, options, sequence_number) do
    case icmp_ping_address(ip, options, sequence_number) do
      {:ok, micros} ->
        "Response from #{address} (#{:inet.ntoa(ip)}): icmp_seq=#{sequence_number} time=#{micros / 1000}ms"

      {:error, reason} ->
        "#{address} (#{:inet.ntoa(ip)}): #{inspect(reason)}"
    end
  end

  # IPv4-only
  defp update_icmp_checksum(<<before::big-16, 0::big-16, rest::binary>>) do
    checksum = icmp_checksum(rest, before)

    <<before::big-16, checksum::big-16, rest::binary>>
  end

  # IPv4-only
  defp icmp_checksum(packet, initial) do
    for <<x::big-16 <- packet>>, reduce: initial do
      acc -> acc + x
    end
    |> fold_sum()
    |> Bitwise.bxor(0xFFFF)
  end

  defp fold_sum(sum) when sum > 0xFFFF, do: fold_sum((sum &&& 0xFFFF) + (sum >>> 16))
  defp fold_sum(sum), do: sum

  defp icmp_ping_address(address, options, sequence_number) do
    timeout = Keyword.get(options, :timeout, 10_000)

    # Payload size is hardcoded to 32 bytes
    # Use a random payload since identifier is unreliable for matching
    # responses. Linux, for example, sets it. Use Enum.take_random instead
    # of :rand.bytes to support OTP 23
    payload = Enum.take_random(0..255, 32) |> :binary.list_to_bin()

    ping_info = %{
      request_type: 0x08,
      reply_type: 0x00,
      identifier: options[:identifier],
      sequence_number: sequence_number,
      payload: payload
    }

    packet = icmp_encode(ping_info)

    with {:ok, socket} <- :socket.open(:inet, :dgram, :icmp),
         addr = make_icmp_bind_addr(options),
         :ok <- socket_bind(socket, addr),
         start <- System.monotonic_time(:microsecond),
         :ok <- :socket.sendto(socket, packet, %{family: :inet, port: 0, addr: address}),
         {:ok, {_, reply_bytes}} <- :socket.recvfrom(socket, [], timeout),
         {:ok, reply} <- icmp_decode(reply_bytes),
         :ok <- icmp_check_reply(reply, ping_info) do
      elapsed_time = System.monotonic_time(:microsecond) - start
      {:ok, elapsed_time}
    end
  end

  # OTP 24 changed the return value from `:socket.bind`. This needs to be
  # accounted for at compile time or else dialyzer will raise an error for
  # the branch that will never match the code required for backwards
  # compatibility.
  if @otp_version >= 24 do
    defp socket_bind(socket, addr), do: :socket.bind(socket, addr)
  else
    defp socket_bind(socket, addr) do
      case :socket.bind(socket, addr) do
        {:ok, _port} -> :ok
        error -> error
      end
    end
  end

  defp make_icmp_bind_addr(options) do
    Keyword.get(options, :ifname)
    |> ifname_to_ip(:inet)
    |> ip_to_bind_addr()
  end

  defp ip_to_bind_addr(:any), do: :any

  defp ip_to_bind_addr(interface_address) do
    %{
      addr: interface_address,
      family: :inet,
      port: 0
    }
  end

  defp icmp_encode(ping_info) do
    <<
      # Type (Echo request)
      ping_info.request_type,
      # Code
      0x00,
      # Checksum
      0x0000::big-16,
      # Identifier
      ping_info.identifier::big-16,
      # Sequence Number
      ping_info.sequence_number::big-16,
      # Payload
      ping_info.payload::binary
    >>
    |> update_icmp_checksum()
  end

  defp icmp_check_reply(reply, ping_info) do
    # Linux fills in the identifier, so it won't be the same on the reply
    if reply.type == ping_info.reply_type and
         reply.code == 0 and
         reply.sequence_number == ping_info.sequence_number and
         reply.payload == ping_info.payload do
      :ok
    else
      {:error, :unexpected_reply}
    end
  end

  # MacOS returns the IPv4 header
  defp icmp_decode(<<_ip_header::20-bytes, icmp_payload::40-bytes>>) do
    icmp_decode(icmp_payload)
  end

  defp icmp_decode(<<icmp_payload::40-bytes>>) do
    if icmp_checksum(icmp_payload, 0) == 0 do
      icmp_decode_contents(icmp_payload)
    else
      {:error, :bad_checksum}
    end
  end

  defp icmp_decode(_packet) do
    {:error, :unexpected_size}
  end

  defp icmp_decode_contents(
         <<type, code, _checksum::big-16, identifier::big-16, sequence_number::big-16,
           payload::binary>>
       ) do
    {:ok,
     %{
       type: type,
       code: code,
       identifier: identifier,
       sequence_number: sequence_number,
       payload: payload
     }}
  end
end
