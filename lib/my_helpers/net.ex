defmodule MyHelpers.Net do
  @moduledoc """
  Network related helpers
  """

  defmacro __using__(_) do
    quote do
      import MyHelpers.Net
    end
  end

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

  require Record
  Record.defrecord(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  @spec nslookup(String.t()) :: :ok
  def nslookup(name) do
    IO.puts("Name:     #{name}")
    name_charlist = to_charlist(name)
    {:ok, v4} = :inet.gethostbyname(name_charlist, :inet)
    print_addresses(v4)
    {:ok, v6} = :inet.gethostbyname(name_charlist, :inet6)
    print_addresses(v6)
  end

  defp print_addresses(hostent) do
    hostent(h_addr_list: ip_list) = hostent
    Enum.each(ip_list, &IO.puts("Address:  #{:inet.ntoa(&1)}"))
  end
end
