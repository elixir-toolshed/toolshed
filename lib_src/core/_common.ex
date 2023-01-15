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

  defp run_or_enter(fun) do
    us = self()

    fun_pid =
      spawn_link(fn ->
        fun.()
        send(us, :done)
      end)

    gets_pid =
      spawn_link(fn ->
        IO.puts("Press enter to stop")
        _ = IO.gets("")
        send(us, :done)
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
