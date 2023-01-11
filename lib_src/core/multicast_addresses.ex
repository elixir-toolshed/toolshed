defmodule Toolshed.Core.MulticastAddresses do
  defmodule Impl do
    @moduledoc false

    @doc false
    @spec read_or_empty(Path.t()) :: String.t()
    def read_or_empty(path) do
      case File.read(path) do
        {:ok, contents} -> contents
        _other -> ""
      end
    end

    @doc false
    @spec process_proc(String.t(), String.t(), String.t()) :: String.t()
    def process_proc(dev_mcast, igmp, igmp6) do
      all =
        process_link(dev_mcast) ++
          process_igmp(igmp) ++
          process_igmp6(igmp6)

      if_map =
        Enum.group_by(all, fn {_type, index, ifname, _address} -> {index, ifname} end, fn {type,
                                                                                           _index,
                                                                                           _ifname,
                                                                                           address} ->
          {type, address}
        end)

      if_keys = Map.keys(if_map) |> Enum.sort()

      Enum.map(if_keys, fn if_key -> format(if_key, if_map[if_key]) end)
      |> IO.chardata_to_string()
    end

    defp format({index, ifname}, addresses) do
      header = "#{index}: #{ifname}\n"
      lines = Enum.map(addresses, fn {type, address} -> "   #{type} #{address}\n" end)
      [header, lines]
    end

    defp process_link(dev_mcast) do
      dev_mcast
      |> String.split("\n")
      |> Enum.map(&process_one_link/1)
      |> Enum.filter(fn x -> x end)
    end

    defp process_one_link(line) do
      case String.split(line, " ", trim: true) do
        [index, ifname, _users, _ignore, mac_address] ->
          {:link, String.to_integer(index), ifname, to_pretty_mac(mac_address)}

        _ ->
          nil
      end
    end

    defp to_pretty_mac(<<a::2-bytes, b::2-bytes, c::2-bytes, d::2-bytes, e::2-bytes, f::2-bytes>>) do
      <<a::binary, ?:, b::binary, ?:, c::binary, ?:, d::binary, ?:, e::binary, ?:, f::binary>>
    end

    defp process_igmp(igmp) do
      all_lines = String.split(igmp, "\n")

      # Skip the header
      lines = tl(all_lines)

      parse_igmp_lines(0, :unknown, lines, [])
    end

    defp parse_igmp_lines(_index, _ifname, [], result), do: result

    defp parse_igmp_lines(index, ifname, [<<lead_char, info::binary>> | rest], result)
         when lead_char in [?\s, ?\t] do
      case String.split(info, [" ", "\t"], trim: true) do
        [address | _rest] ->
          record = {:inet, index, ifname, to_pretty_ipv4(address)}
          parse_igmp_lines(index, ifname, rest, [record | result])

        _other ->
          parse_igmp_lines(index, ifname, rest, result)
      end
    end

    defp parse_igmp_lines(index, ifname, [if_line | rest], result) do
      case String.split(if_line, [" ", "\t"], trim: true) do
        [new_index, new_ifname | _rest] ->
          parse_igmp_lines(String.to_integer(new_index), new_ifname, rest, result)

        _ ->
          parse_igmp_lines(index, ifname, rest, result)
      end
    end

    defp process_igmp6(igmp6) do
      igmp6
      |> String.split("\n")
      |> Enum.map(&process_one_igmp6/1)
      |> Enum.filter(fn x -> x end)
    end

    defp process_one_igmp6(line) do
      case String.split(line, " ", trim: true) do
        [index, ifname, address, _users, _offset, _ignore] ->
          {:inet6, String.to_integer(index), ifname, to_pretty_ipv6(address)}

        _ ->
          nil
      end
    end

    defp to_pretty_ipv4(<<a::2-bytes, b::2-bytes, c::2-bytes, d::2-bytes>>) do
      {
        String.to_integer(d, 16),
        String.to_integer(c, 16),
        String.to_integer(b, 16),
        String.to_integer(a, 16)
      }
      |> :inet.ntoa()
      |> to_string()
    end

    defp to_pretty_ipv6(
           <<a::4-bytes, b::4-bytes, c::4-bytes, d::4-bytes, e::4-bytes, f::4-bytes, g::4-bytes,
             h::4-bytes>>
         ) do
      {
        String.to_integer(a, 16),
        String.to_integer(b, 16),
        String.to_integer(c, 16),
        String.to_integer(d, 16),
        String.to_integer(e, 16),
        String.to_integer(f, 16),
        String.to_integer(g, 16),
        String.to_integer(h, 16)
      }
      |> :inet.ntoa()
      |> to_string()
    end
  end

  @doc """
  List all active multicast addresses

  This lists out multicast addresses by network interface
  similar to `ip maddr show`. It currently only works on
  Linux.
  """
  @spec multicast_addresses() :: :ok
  def multicast_addresses() do
    dev_mcast = Impl.read_or_empty("/proc/net/dev_mcast")
    igmp = Impl.read_or_empty("/proc/net/igmp")
    igmp6 = Impl.read_or_empty("/proc/net/igmp6")

    Impl.process_proc(dev_mcast, igmp, igmp6)
    |> IO.puts()
  end
end
