defmodule Toolshed.Top.Report do
  @moduledoc false

  @typedoc """
  Options:

  * `:order` - the sort order for the results (`:reductions`, `:delta_reductions`,
    `:mailbox`, `:delta_mailbox`, `:total_heap_size`, `:delta_total_heap_size`, `:heap_size`,
    `:delta_heap_size`, `:stack_size`, `:delta_stack_size`)
  * `:rows`     - the number of rows to use
  * `:columns`  - the number of columns to use

  """
  @type options() :: %{rows: pos_integer(), columns: pos_integer(), order: atom()}

  @spec back_to_the_top(options()) :: iolist()
  def back_to_the_top(options) do
    [IO.ANSI.cursor_up(options.rows - 3), "\r"]
  end

  @doc """
  Create a top process report
  """
  @spec generate(list(), options()) :: iolist()
  def generate(info, options) do
    n = options.rows - 5

    content = info |> Enum.sort(sort(options.order)) |> Enum.take(n) |> Enum.map(&format/1)

    [format_summary(info), format_header(), content]
  end

  defp sort(:reductions), do: fn x, y -> x.reductions > y.reductions end
  defp sort(:delta_reductions), do: fn x, y -> x.delta_reductions > y.delta_reductions end
  defp sort(:mailbox), do: fn x, y -> x.message_queue_len > y.message_queue_len end

  defp sort(:delta_mailbox),
    do: fn x, y -> x.delta_message_queue_len > y.delta_message_queue_len end

  defp sort(:total_heap_size), do: fn x, y -> x.total_heap_size > y.total_heap_size end

  defp sort(:delta_total_heap_size),
    do: fn x, y -> x.delta_total_heap_size > y.delta_total_heap_size end

  defp sort(:heap_size), do: fn x, y -> x.heap_size > y.heap_size end
  defp sort(:delta_heap_size), do: fn x, y -> x.delta_heap_size > y.delta_heap_size end
  defp sort(:stack_size), do: fn x, y -> x.stack_size > y.stack_size end
  defp sort(:delta_stack_size), do: fn x, y -> x.delta_stack_size > y.delta_stack_size end
  defp sort(_other), do: sort(:delta_reductions)

  defp format_summary(infos) do
    cnt = Enum.count(infos)

    "Total processes: #{cnt}\n"
  end

  defp format_header() do
    [
      IO.ANSI.clear_line(),
      IO.ANSI.cyan(),
      :io_lib.format(
        "~-12ts ~-28ts ~5ts/~-5ts ~5ts/~-5ts ~5ts/~-5ts ~5ts/~-5ts ~5ts/~-5ts~n",
        [
          "Application",
          "Name or PID",
          "Reds",
          "Δ",
          "Mbox",
          "Δ",
          "Total",
          "Δ",
          "Heap",
          "Δ",
          "Stack",
          "Δ"
        ]
      ),
      IO.ANSI.white()
    ]
  end

  defp format(info) do
    :io_lib.format(
      IO.ANSI.clear_line() <>
        "~-12ts ~-28ts ~5ts/~-5ts ~5ts/~-5ts ~5ts/~-5ts ~5ts/~-5ts ~5ts/~-5ts~n",
      [
        String.slice(to_string(info.application), 0, 12),
        String.slice(info.name, 0, 28),
        format_num(info.reductions),
        format_num(info.delta_reductions),
        format_num(info.message_queue_len),
        format_num(info.delta_message_queue_len),
        format_num(info.total_heap_size),
        format_num(info.delta_total_heap_size),
        format_num(info.heap_size),
        format_num(info.delta_heap_size),
        format_num(info.stack_size),
        format_num(info.delta_stack_size)
      ]
    )
  end

  defp format_num(x) when x < 10 * 1024, do: Integer.to_string(x)
  defp format_num(x) when x < 10 * 1024 * 1024, do: Integer.to_string(div(x, 1024)) <> "K"
  defp format_num(x), do: Integer.to_string(div(x, 1024 * 1024)) <> "M"
end
