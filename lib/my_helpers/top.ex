defmodule MyHelpers.Top do
  @default_n 10

  @moduledoc """
  Find the top processes
  """

  defmacro __using__(_) do
    quote do
      import MyHelpers.Top,
        only: [
          top: 0,
          top: 1,
          top_reductions: 0,
          top_reductions: 1,
          top_mailbox: 0,
          top_mailbox: 1,
          top_total_heap_size: 0,
          top_total_heap_size: 1,
          top_heap_size: 0,
          top_heap_size: 1,
          top_stack_size: 0,
          top_stack_size: 1
        ]
    end
  end

  @spec top_reductions(any()) :: :"do not show this result in output"
  def top_reductions(n \\ @default_n), do: top(order: :reductions, n: n)
  @spec top_mailbox(any()) :: :"do not show this result in output"
  def top_mailbox(n \\ @default_n), do: top(order: :mailbox, n: n)
  @spec top_total_heap_size(any()) :: :"do not show this result in output"
  def top_total_heap_size(n \\ @default_n), do: top(order: :total_heap_size, n: n)
  @spec top_heap_size(any()) :: :"do not show this result in output"
  def top_heap_size(n \\ @default_n), do: top(order: :heap_size, n: n)
  @spec top_stack_size(any()) :: :"do not show this result in output"
  def top_stack_size(n \\ @default_n), do: top(order: :stack_size, n: n)

  @doc """
  List the top processes

  Options
  """
  def top(opts \\ []) do
    order = Keyword.get(opts, :order, :reductions)
    n = Keyword.get(opts, :n, @default_n)

    Process.list()
    |> Enum.map(&process_info/1)
    |> Enum.filter(fn x -> x != %{} end)
    |> Enum.sort(sort(order))
    |> Enum.take(n)
    |> format_header
    |> Enum.each(&format/1)

    IEx.dont_display_result()
  end

  defp sort(:reductions), do: fn x, y -> x.reductions > y.reductions end
  defp sort(:mailbox), do: fn x, y -> x.message_queue_len > y.message_queue_len end
  defp sort(:total_heap_size), do: fn x, y -> x.total_heap_size > y.total_heap_size end
  defp sort(:heap_size), do: fn x, y -> x.heap_size > y.heap_size end
  defp sort(:stack_size), do: fn x, y -> x.stack_size > y.stack_size end
  defp sort(_other), do: sort(:reductions)

  def process_info(pid) do
    organize_info(pid, Process.info(pid), get_application(pid))
  end

  # Ignore deceased processes
  defp organize_info(_pid, nil, _app_info), do: %{}

  defp organize_info(pid, info, application) do
    %{
      application: application,
      total_heap_size: Keyword.get(info, :total_heap_size),
      heap_size: Keyword.get(info, :heap_size),
      stack_size: Keyword.get(info, :stack_size),
      reductions: Keyword.get(info, :reductions),
      message_queue_len: Keyword.get(info, :message_queue_len),
      name: Keyword.get(info, :registered_name, pid)
    }
  end

  defp get_application(pid) do
    case :application.get_application(pid) do
      {:ok, app} -> app
      :undefined -> :undefined
    end
  end

  defp format_header(infos) do
    :io.format(
      IO.ANSI.cyan() <> "~-16ts ~-24ts ~10ts ~10ts ~10ts ~10ts ~10ts~n" <> IO.ANSI.white(),
      ["OTP Application", "Name/PID", "Reductions", "Mailbox", "Total", "Heap", "Stack"]
    )

    infos
  end

  defp format(info) do
    :io.format(
      "~-16ts ~-24ts ~10B ~10B ~10B ~10B ~10B~n",
      [
        String.slice(to_string(info.application), 0, 16),
        String.slice(inspect(info.name), 0, 24),
        info.reductions,
        info.message_queue_len,
        info.total_heap_size,
        info.heap_size,
        info.stack_size
      ]
    )
  end
end
