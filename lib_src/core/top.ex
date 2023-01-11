defmodule Toolshed.Core.Top do
  alias Toolshed.Top.Server

  @default_rows 23
  @default_columns 80

  @doc """
  Interactively show the top Elixir processes

  This is intended to be called from the IEx prompt and will periodically
  update the console with the top processes. Press enter to exit.

  Options:

  * `:order` - the sort order for the results (`:reductions`, `:delta_reductions`,
    `:mailbox`, `:delta_mailbox`, `:total_heap_size`, `:delta_total_heap_size`, `:heap_size`,
    `:delta_heap_size`, `:stack_size`, `:delta_stack_size`)
  """
  @spec top(keyword()) :: :"do not show this result in output"
  def top(opts \\ []) do
    options = %{
      order: Keyword.get(opts, :order, :delta_reductions),
      rows: rows(),
      columns: columns()
    }

    IO.puts("Press enter to stop\n")

    {:ok, pid} = Server.start_link(options)
    _ = IO.gets("")
    Server.stop(pid)

    IEx.dont_display_result()
  end

  defp rows() do
    case :io.rows() do
      {:ok, rows} -> rows
      _ -> @default_rows
    end
  end

  defp columns() do
    case :io.columns() do
      {:ok, columns} -> columns
      _ -> @default_columns
    end
  end
end
