defmodule Toolshed.Top.Processes do
  @moduledoc false

  @spec new() :: :ets.table()
  def new() do
    :ets.new(:toolshed_top, [])
  end

  @spec info(atom()) :: list()
  def info(tid) do
    Process.list()
    |> Enum.map(&process_info/1)
    |> Enum.filter(fn info -> info != %{} end)
    |> Enum.map(fn info ->
      previous_info = :ets.lookup(tid, info.pid)
      d = add_deltas(info, previous_info)
      :ets.insert(tid, {info.pid, info})
      d
    end)
  end

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
      name -> name |> to_string() |> friendly_module_name()
    end
  end

  defp initial_call_name(pid, info) do
    case get_in(info, [:dictionary, :"$initial_call"]) do
      {m, f, a} ->
        module = m |> to_string() |> friendly_module_name()

        IO.chardata_to_string([
          :erlang.pid_to_list(pid),
          "=",
          module,
          ".",
          to_string(f),
          "/",
          to_string(a)
        ])

      _ ->
        nil
    end
  end

  defp friendly_module_name("Elixir." <> rest), do: rest
  defp friendly_module_name(other), do: other

  defp get_application(pid) do
    case :application.get_application(pid) do
      {:ok, app} -> app
      :undefined -> :undefined
    end
  end

  defp short_pid_to_string(pid) do
    IO.chardata_to_string(:erlang.pid_to_list(pid))
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
end
