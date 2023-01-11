defmodule Toolshed.Core.LogAttach do
  # Utilities for attaching and detaching to the log
  #
  # These utilities configure Elixir's console backend to attach
  # to the current group leader. This makes it work over `ssh` sessions
  # and play well with the IEx prompt.

  @process_name Toolshed.Log

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

  @doc """
  Attach the current session to the Elixir logger

  This forwards incoming log messages to the terminal. Call `detach/0` to stop
  the messages.

  Behind the scenes, this uses Elixir's built-in console logger and can be
  configured similarly. See the [Logger console backend
  documentation](https://hexdocs.pm/logger/Logger.html#module-console-backend)
  for details. The following are useful options:

  * `:level` - the minimum log level to report. E.g., specify `level: :warning`
    to only see warnings and errors.
  * `:metadata` - a list of metadata keys to show or `:all`

  Unspecified options use either the console backend's default or those found
  in the application environment for the `:console` Logger backend.
  """
  @spec log_attach(keyword()) :: {:error, any} | {:ok, :undefined | pid}
  def log_attach(options \\ []) do
    case Process.get(@process_name) do
      nil ->
        all_options = Keyword.put(options, :device, Process.group_leader())
        backend = {Logger.Backends.Console, all_options}

        {:ok, pid} = GenServer.start(Watcher, {Process.group_leader(), backend})

        Process.put(@process_name, {pid, backend})

        Logger.add_backend({Logger.Backends.Console, all_options})

      _other ->
        {:error, :detach_first}
    end
  end
end
