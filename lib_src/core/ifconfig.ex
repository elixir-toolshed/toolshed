defmodule Toolshed.Core.Ifconfig do
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
      |> Enum.map_join(":", &:io_lib.format("~2.16.0b", [&1]))

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
