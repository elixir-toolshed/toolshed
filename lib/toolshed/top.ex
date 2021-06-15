defmodule Toolshed.Top do
  @moduledoc """
  Find the top processes
  """

  @default_n 10

  @doc """
  Interactively show the top Elixir processes

  This is intended to be called from the IEx prompt and will periodically
  update the console with the top processes. Press enter to exit.

  Options:

  * `:order` - the sort order for the results (`:reductions`, `:delta_reductions`,
    `:mailbox`, `:delta_mailbox`, `:total_heap_size`, `:delta_total_heap_size`, `:heap_size`,
    `:delta_heap_size`, `:stack_size`, `:delta_stack_size`)
  * `:n`     - the max number of processes to list
  """
  @spec top(keyword()) :: :ok
  def top(opts \\ []) do
    options = process_options(opts)

    IO.puts("Press enter to stop\n")

    {:ok, pid} = Toolshed.Top.Server.start_link(options)
    _ = IO.gets("")
    Toolshed.Top.Server.stop(pid)
  end

  # TODO - validate options
  defp process_options(opts) do
    order = Keyword.get(opts, :order, :delta_reductions)
    n = Keyword.get(opts, :n, @default_n)

    %{order: order, n: n}
  end
end
