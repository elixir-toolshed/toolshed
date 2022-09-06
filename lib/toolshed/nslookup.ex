defmodule Toolshed.Nslookup do
  @moduledoc ""

  require Record

  @doc false
  Record.defrecordp(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

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
end
