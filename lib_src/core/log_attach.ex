# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
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
    def init({watch_pid, detach_fn}) do
      Process.monitor(watch_pid)
      {:ok, detach_fn}
    end

    @impl GenServer
    def handle_info({:DOWN, _ref, :process, _pid, _reason}, detach_fn) do
      detach_fn.()
      {:stop, :normal, detach_fn}
    end

    @impl GenServer
    def terminate(_reason, detach_fn) do
      detach_fn.()
    end
  end

  @doc """
  Attach the current session to the Elixir logger

  This forwards incoming log messages to the terminal. Call `log_detach/0` to
  stop the messages.

  Behind the scenes, this uses Erlang's `logger_std_h` and Elixir's log
  formatter. Options include all of the ones from
  [Logger.Formatter](https://hexdocs.pm/logger/main/Logger.Formatter.html#new/1)
  and the ability to set the level.

  For ease of use, here are the common options:

  * `:level` - the minimum log level to report. E.g., specify `level: :warning`
    to only see warnings and errors.
  * `:metadata` - a list of metadata keys to show or `:all`
  """
  @spec log_attach(keyword()) :: :ok
  def log_attach(options \\ []) do
    watcher_pid = Process.get(@process_name)

    if is_pid(watcher_pid) do
      _ = GenServer.stop(watcher_pid)
    end

    detach_fn = do_attach(options)

    {:ok, pid} = GenServer.start(Watcher, {Process.group_leader(), detach_fn})
    Process.put(@process_name, pid)
    :ok
  end

  if String.to_integer(System.otp_release()) >= 26 do
    # Use the Erlang logger in OTP 26+
    defp do_attach(options) do
      formatter_options =
        Keyword.take(options, [:colors, :format, :metadata, :truncate, :utc_log])

      default_options = %{
        config: %{type: {:device, Process.group_leader()}},
        formatter: Logger.default_formatter(formatter_options)
      }

      all_options = Enum.reduce(options, default_options, &add_option/2)
      id = Module.concat(@process_name, inspect(self()))
      :ok = :logger.add_handler(id, :logger_std_h, all_options)

      fn -> :logger.remove_handler(id) end
    end

    defp add_option({:level, level}, acc), do: Map.put(acc, :level, level)
    defp add_option(_, acc), do: acc
  else
    # Use the Elixir logger for OTP 25 and earlier
    defp do_attach(options) do
      all_options = Keyword.put(options, :device, Process.group_leader())
      backend = {Logger.Backends.Console, all_options}

      Logger.add_backend(backend)

      fn -> Logger.remove_backend(backend) end
    end
  end
end
