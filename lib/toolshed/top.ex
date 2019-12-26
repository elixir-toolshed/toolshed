defmodule Toolshed.Top do
  @default_n 10

  @moduledoc """
  Find the top processes
  """

  alias Toolshed.Result

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

  Options:

  * `:order` - the sort order for the results (`:reductions`, `:delta_reductions`,
    `:mailbox`, `:delta_mailbox`, `:total_heap_size`, `:delta_total_heap_size`, `:heap_size`,
    `:delta_heap_size`, `:stack_size`, `:delta_stack_size`)
  * `:n`     - the max number of processes to list
  """
  @spec top(keyword()) :: Result.t()
  def top(opts \\ []) do
    order = Keyword.get(opts, :order, :delta_reductions)
    n = Keyword.get(opts, :n, @default_n)
    tid = toolshed_top_tid()

    all_infos =
      Process.list()
      |> Enum.map(&process_info/1)
      |> Enum.filter(fn info -> info != %{} end)
      |> Enum.map(fn info ->
        previous_info = :ets.lookup(tid, info.pid)
        d = add_deltas(info, previous_info)
        :ets.insert(tid, {info.pid, info})
        d
      end)
      |> Enum.sort(sort(order))

    infos = Enum.take(all_infos, n)

    [print_summary(all_infos), format_header(), Enum.map(infos, &format/1)]
    |> Result.new()
  end

  defp toolshed_top_tid() do
    case Process.get(:toolshed_top) do
      nil ->
        tid = :ets.new(:toolshed_top, [])
        Process.put(:toolshed_top, tid)
        tid

      tid ->
        tid
    end
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

  defp process_info(pid) do
    organize_info(pid, Process.info(pid))
  end

  # Ignore deceased processes
  defp organize_info(_pid, nil), do: %{}

  defp organize_info(pid, info) do
    %{
      pid: pid,
      application: get_application(pid),
      total_heap_size: Keyword.get(info, :total_heap_size),
      heap_size: Keyword.get(info, :heap_size),
      stack_size: Keyword.get(info, :stack_size),
      reductions: Keyword.get(info, :reductions),
      message_queue_len: Keyword.get(info, :message_queue_len),
      name: process_name(pid, info)
    }
  end

  defp process_name(pid, info) do
    registered_name(info) || initial_call_name(pid, info) || short_pid_to_string(pid)
  end

  defp registered_name(info) do
    case Keyword.get(info, :registered_name) do
      nil -> nil
      name -> to_string(name)
    end
  end

  defp initial_call_name(pid, info) do
    case get_in(info, [:dictionary, :"$initial_call"]) do
      {m, f, a} ->
        IO.iodata_to_binary([
          :erlang.pid_to_list(pid),
          "=",
          to_string(m),
          ".",
          to_string(f),
          "/",
          to_string(a)
        ])

      _ ->
        nil
    end
  end

  defp short_pid_to_string(pid) do
    IO.iodata_to_binary(:erlang.pid_to_list(pid))
  end

  defp add_deltas(info, []) do
    %{
      delta_total_heap_size: info.total_heap_size,
      delta_heap_size: info.heap_size,
      delta_stack_size: info.stack_size,
      delta_reductions: info.reductions,
      delta_message_queue_len: info.message_queue_len
    }
    |> Map.merge(info)
  end

  defp add_deltas(info, [{_pid, previous_info}]) do
    %{
      delta_total_heap_size: info.total_heap_size - previous_info.total_heap_size,
      delta_heap_size: info.heap_size - previous_info.heap_size,
      delta_stack_size: info.stack_size - previous_info.stack_size,
      delta_reductions: info.reductions - previous_info.reductions,
      delta_message_queue_len: info.message_queue_len - previous_info.message_queue_len
    }
    |> Map.merge(info)
  end

  defp get_application(pid) do
    case :application.get_application(pid) do
      {:ok, app} -> app
      :undefined -> :undefined
    end
  end

  defp print_summary(infos) do
    cnt = Enum.count(infos)

    "Total processes: #{cnt}\n\n"
  end

  defp format_header() do
    [
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
