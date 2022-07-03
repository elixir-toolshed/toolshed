defmodule Toolshed.Log do
  @moduledoc false
  # Utilities for attaching and detaching to the log
  #
  # These utilities configure Elixir's console backend to attach
  # to the current group leader. This makes it work over `ssh` sessions
  # and play well with the IEx prompt.

  defmodule Watcher do
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
end
