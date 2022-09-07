defmodule Toolshed.Log.Watcher do
  @moduledoc false

  use GenServer

  @impl GenServer
  def init({watch_pid, backend}) do
    Process.monitor(watch_pid)
    {:ok, backend}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, backend) do
    _ = Logger.remove_backend(backend)
    {:stop, :normal, backend}
  end
end
