defmodule Toolshed.Utils do
  @moduledoc false

  @doc false
  @spec check_app(atom) :: :ok
  def check_app(app) do
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
