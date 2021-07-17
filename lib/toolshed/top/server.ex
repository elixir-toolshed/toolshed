defmodule Toolshed.Top.Server do
  @moduledoc false
  use GenServer

  alias Toolshed.Top.{Processes, Report}

  @spec start_link(map()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec stop(GenServer.server()) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  @impl GenServer
  def init(options) do
    _ = :timer.send_interval(1000, :refresh_top)

    processes = Processes.new()

    Processes.info(processes)
    |> Report.generate(options)
    |> IO.write()

    {:ok, %{options: options, processes: processes}}
  end

  @impl GenServer
  def handle_info(:refresh_top, state) do
    report =
      Processes.info(state.processes)
      |> Report.generate(state.options)

    IO.write([
      Report.back_to_the_top(state.options),
      report
    ])

    {:noreply, state}
  end
end
