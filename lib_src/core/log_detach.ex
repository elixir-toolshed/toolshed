defmodule Toolshed.Core.LogDetach do
  @process_name Toolshed.Log

  @doc """
  Detach the current session from the Elixir logger
  """
  @spec log_detach :: :ok | {:error, :not_attached}
  def log_detach() do
    case Process.get(@process_name) do
      pid when is_pid(pid) ->
        _ = GenServer.stop(pid)
        Process.delete(@process_name)
        :ok

      _ ->
        {:error, :not_attached}
    end
  end
end
