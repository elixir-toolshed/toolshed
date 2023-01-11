defmodule Toolshed.Core.LogDetach do
  @process_name Toolshed.Log

  @doc """
  Detach the current session from the Elixir logger
  """
  @spec log_detach :: :ok | {:error, :not_attached | :not_found}
  def log_detach() do
    case Process.get(@process_name) do
      nil ->
        {:error, :not_attached}

      {pid, backend} ->
        Process.delete(@process_name)
        GenServer.stop(pid)
        Logger.remove_backend(backend)
    end
  end
end
