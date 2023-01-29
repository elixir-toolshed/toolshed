defmodule Toolshed.Core.Common do
  # This file contains definitions that are used by more than one helper.
  # Everything is private.
  require Record

  @doc false
  Record.defrecordp(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

  defp get_hosts_by_name(address, family) do
    case :inet.gethostbyname(to_charlist(address), family) do
      {:ok, hostent} ->
        hostent(h_addr_list: ip_list) = hostent
        ip_list

      _ ->
        []
    end
  end

  defp resolve_addr(address) do
    case gethostbyname(address, :inet) || gethostbyname(address, :inet6) do
      nil -> {:error, "Error resolving #{address}"}
      ip -> {:ok, ip}
    end
  end

  defp gethostbyname(address, family) do
    get_hosts_by_name(address, family) |> List.first()
  end

  defp ifname_to_ip(nil, _family), do: :any

  defp ifname_to_ip(ifname, family) do
    ifname_cl = to_charlist(ifname)

    with {:ok, ifaddrs} <- :inet.getifaddrs(),
         {_, params} <- Enum.find(ifaddrs, fn {k, _v} -> k == ifname_cl end),
         [addr | _] <- find_addr_by_family(params, family) do
      addr
    else
      _ ->
        # HACK: Give an IP address that will give an address error so
        # that if the interface appears that it will work.
        {192, 0, 2, 1}
    end
  end

  defp find_addr_by_family(params, family) do
    addr_size = family_to_tuple_size(family)
    for {:addr, addr} when tuple_size(addr) == addr_size <- params, do: addr
  end

  defp family_to_tuple_size(:inet), do: 4
  defp family_to_tuple_size(:inet6), do: 6

  defp ip_to_family({_, _, _, _}), do: :inet
  defp ip_to_family({_, _, _, _, _, _}), do: :inet6

  defp run_or_enter(fun) do
    us = self()

    fun_pid =
      spawn_link(fn ->
        fun.()
        send(us, :done)
      end)

    gets_pid =
      spawn_link(fn ->
        if IO.gets("Press enter to stop") != :eof do
          send(us, :done)
        end
      end)

    # Wait for either the pings to stop or enter to be pressed
    receive do
      :done -> :ok
    end

    # Clean up the processes
    Process.unlink(fun_pid)
    Process.exit(fun_pid, :kill)
    Process.unlink(gets_pid)
    Process.exit(gets_pid, :kill)

    # Clean up a second `:done` in case both complete simultaneously
    receive do
      :done -> :ok
    after
      0 -> :ok
    end
  end

  defp check_app(app) do
    case Application.ensure_all_started(app) do
      {:ok, _} ->
        :ok

      {:error, _} ->
        raise RuntimeError, """
        #{inspect(app)} can't be started.
        This probably means that it isn't in the OTP release.
        To fix, edit your mix.exs and add #{inspect(app)} to the :extra_applications list.
        """
    end
  end
end
