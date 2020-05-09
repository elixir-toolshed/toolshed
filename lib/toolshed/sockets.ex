defmodule Toolshed.Sockets do
  # The interesting parts of the code in this module are copied from phoenix_live_dashboard.any()
  # See https://github.com/phoenixframework/phoenix_live_dashboard/blob/master/lib/phoenix/live_dashboard/system_info.ex.
  #
  # Phoenix LiveDashboard is has the following license:
  #
  # MIT License. Copyright (c) 2019 Michael Crumm, Chris McCord, José Valim.
  #

  @moduledoc false

  @inet_ports ['tcp_inet', 'udp_inet', 'sctp_inet']

  @doc """
  List all open sockets known to Erlang

  ## Examples

      iex)> sockets
           Port      |   Module   |   Sent   | Received |    Local Address     |   Foreign Address    |   State   |  Type   | Owner
       ------------- | ---------- | -------- | -------- | -------------------- | -------------------- | --------- | ------- | -----
      #Port<0.119>   | inet_tcp   |        0 |        0 |                 *:22 |                  *:* | ACCEPTING |  stream | <0.2253.0>
      #Port<0.165>   | inet6_udp  |    53906 |    54885 |              *:33168 |                  *:* |      IDLE |   dgram | <0.2794.0>
      #Port<0.162>   | inet6_udp  |    53922 |    54869 |              *:33256 |                  *:* |      IDLE |   dgram | <0.2788.0>
      #Port<0.163>   | inet6_udp  |    53999 |    54869 |              *:38951 |                  *:* |      IDLE |   dgram | <0.2791.0>
      #Port<0.135>   | inet_tcp   |        0 |        0 |               *:4443 |                  *:* | ACCEPTING |  stream | <0.2598.0>
      #Port<0.159>   | inet6_udp  |    54994 |    55826 |              *:45203 |                  *:* |      IDLE |   dgram | <0.2765.0>
      #Port<0.166>   | inet6_udp  |    61136 |   182947 |              *:48495 |                  *:* |      IDLE |   dgram | <0.2797.0>
      #Port<0.139>   | inet_udp   |        0 |        0 |               *:5353 |                  *:* |      IDLE |   dgram | <0.2714.0>
      #Port<0.164>   | inet6_udp  |    53829 |    54218 |              *:58840 |                  *:* |      IDLE |   dgram | <0.2793.0>
      #Port<0.167>   | inet6_udp  |    55200 |    77575 |              *:60111 |                  *:* |      IDLE |   dgram | <0.2798.0>
      #Port<0.118>   | inet_tcp   |        0 |        0 |               *:8989 |                  *:* | ACCEPTING |  stream | <0.2248.0>
      #Port<0.1569>  | inet_tcp   |   370566 |    38108 |     192.168.99.37:22 |    192.168.7.5:37184 | CONNECTED |  stream | <0.3538.0>
      #Port<0.175>   | inet_tcp   |    17553 |    17300 |  192.168.99.37:34953 |     52.3.159.142:443 | CONNECTED |  stream | <0.2855.0>
      #Port<0.1541>  | inet_tcp   |     6025 |     5390 |   192.168.99.37:4443 |    192.168.7.5:40800 | CONNECTED |  stream | <0.3506.0>
      #Port<0.1542>  | inet_tcp   |   867349 |    13275 |   192.168.99.37:4443 |    192.168.7.5:40812 | CONNECTED |  stream | <0.3513.0>
      #Port<0.173>   | inet_tcp   |    29349 |    26067 |  192.168.99.37:58279 |     18.208.87.62:443 | CONNECTED |  stream | <0.2846.0>
      #Port<0.158>   | inet6_udp  |     3490 |     6201 |   fd00:aaaa::2:41230 |                  *:* |      IDLE |   dgram | <0.2754.0>
      #Port<0.10>    | local_udp  |        0 |     3477 |       local:/dev/log |                  *:* |      IDLE |   dgram | <0.2107.0>
      #Port<0.126>   | local_udp  |        0 |     1133 | local:/tmp/nerves_ti |                  *:* |      IDLE |   dgram | <0.2382.0>
      #Port<0.26>    | local_udp  |        0 |    79886 | local:/tmp/vintage_n |                  *:* |      IDLE |   dgram | <0.2126.0>
      #Port<0.124>   | local_udp  |        0 |        0 | local:/tmp/vintage_n |                  *:* |      IDLE |   dgram | <0.2370.0>
      #Port<0.117>   | local_udp  |     1752 |    29148 | local:/tmp/vintage_n |                  *:* |      IDLE |   dgram | <0.2191.0>
      22 sockets in use

  """
  @spec sockets() :: :"do not show this result in output"
  def sockets() do
    {info, count} = sockets_callback(nil, :local_address, 100)

    [
      "     Port      |   Module   |   Sent   | Received |    Local Address     |   Foreign Address    |   State   |  Type   | Owner\n",
      " ------------- | ---------- | -------- | -------- | -------------------- | -------------------- | --------- | ------- | -----\n",
      Enum.map(info, &format_socket/1),
      "#{count} sockets in use\n"
    ]
    |> IO.puts()

    :"do not show this result in output"
  end

  defp format_socket(info) do
    :io_lib.format("~-14w | ~-10w | ~8b | ~8b | ~20s | ~20s | ~9s | ~7w | ~10w~n", [
      info[:port],
      info[:module],
      info[:send_oct],
      info[:recv_oct],
      info[:local_address],
      info[:foreign_address],
      info[:state],
      info[:type],
      info[:connected]
    ])
  end

  defp sockets_callback(search, sort_by, limit) do
    sorter = &<=/2

    sockets =
      for port <- Port.list(), info = socket_info(port), show_socket?(info, search), do: info

    count = length(sockets)
    sockets = sockets |> Enum.sort_by(&Keyword.fetch!(&1, sort_by), sorter) |> Enum.take(limit)
    {sockets, count}
  end

  defp socket_info(port) do
    with info when not is_nil(info) <- Port.info(port),
         true <- info[:name] in @inet_ports,
         {:ok, stat} <- :inet.getstat(port, [:send_oct, :recv_oct]),
         {:ok, state} <- :prim_inet.getstatus(port),
         {:ok, {_, type}} <- :prim_inet.gettype(port),
         module <- inet_module_lookup(port) do
      [
        port: port,
        module: module,
        local_address: format_address(:inet.sockname(port)),
        foreign_address: format_address(:inet.peername(port)),
        state: format_socket_state(state),
        type: type
      ] ++ info ++ stat
    else
      _ -> nil
    end
  end

  defp show_socket?(_info, nil), do: true

  # defp show_socket?(info, search) do
  #   info[:local_address] =~ search || info[:foreign_address] =~ search
  # end

  defp inet_module_lookup(port) do
    case :inet_db.lookup_socket(port) do
      {:ok, module} -> module
      _ -> "prim_inet"
    end
  end

  # The address is formatted based on the implementation of `:inet.fmt_addr/2`
  defp format_address({:error, :enotconn}), do: "*:*"
  defp format_address({:error, _}), do: " "

  defp format_address({:ok, address}) do
    case address do
      {{0, 0, 0, 0}, port} -> "*:#{port}"
      {{0, 0, 0, 0, 0, 0, 0, 0}, port} -> "*:#{port}"
      {{127, 0, 0, 1}, port} -> "localhost:#{port}"
      {{0, 0, 0, 0, 0, 0, 0, 1}, port} -> "localhost:#{port}"
      {:local, path} -> "local:#{path}"
      {ip, port} -> "#{:inet.ntoa(ip)}:#{port}"
    end
  end

  # See `:inet.fmt_status`
  defp format_socket_state(flags) do
    case Enum.sort(flags) do
      [:accepting | _] -> "ACCEPTING"
      [:bound, :busy, :connected | _] -> "BUSY"
      [:bound, :connected | _] -> "CONNECTED"
      [:bound, :listen, :listening | _] -> "LISTENING"
      [:bound, :listen | _] -> "LISTEN"
      [:bound, :connecting | _] -> "CONNECTING"
      [:bound, :open] -> "BOUND"
      [:connected, :open] -> "CONNECTED"
      [:open] -> "IDLE"
      [] -> "CLOSED"
      sorted -> inspect(sorted)
    end
  end
end
