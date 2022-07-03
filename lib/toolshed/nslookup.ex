defmodule Toolshed.Nslookup do
  @moduledoc false

  require Record

  @doc false
  Record.defrecord(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  @type hostent :: {:hostent, any, any, any, any, any}

  @spec print_addresses(hostent) :: :ok
  def print_addresses(hostent) do
    hostent(h_addr_list: ip_list) = hostent
    Enum.each(ip_list, &IO.puts("Address:  #{:inet.ntoa(&1)}"))
  end
end
