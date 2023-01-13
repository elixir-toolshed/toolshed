defmodule Toolshed.Core.Common do
  # This file contains definitions that are used by more than one helper.
  # Everything is private.
  require Record

  @doc false
  Record.defrecordp(:hostent, Record.extract(:hostent, from_lib: "kernel/include/inet.hrl"))

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
