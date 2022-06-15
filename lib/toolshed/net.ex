defmodule Toolshed.Net do
  @moduledoc """
  Network related helpers
  """

  require Record

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

    case :inet.gethostbyname(name_charlist, :inet) do
      {:ok, v4} -> print_addresses(v4)
      {:error, :nxdomain} -> IO.puts("IPv4 lookup failed")
    end

    case :inet.gethostbyname(name_charlist, :inet6) do
      {:ok, v6} -> print_addresses(v6)
      {:error, :nxdomain} -> IO.puts("IPv6 lookup failed")
    end

    IEx.dont_display_result()
  end

  defp print_addresses(hostent) do
    hostent(h_addr_list: ip_list) = hostent
    Enum.each(ip_list, &IO.puts("Address:  #{:inet.ntoa(&1)}"))
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
