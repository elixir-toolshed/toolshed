defmodule Toolshed.Core.Nslookup do
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

    case get_hosts_by_name(name_charlist, :inet) do
      [] -> IO.puts("IPv4 lookup failed")
      v4 -> print_addresses(v4)
    end

    case get_hosts_by_name(name_charlist, :inet6) do
      [] -> IO.puts("IPv6 lookup failed")
      v6 -> print_addresses(v6)
    end

    IEx.dont_display_result()
  end

  defp print_addresses(addresses) do
    Enum.each(addresses, &IO.puts("Address:  #{:inet.ntoa(&1)}"))
  end
end
