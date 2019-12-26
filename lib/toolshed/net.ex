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
  @spec nslookup(String.t()) :: Result.t()
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
