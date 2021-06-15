defmodule Toolshed.Top.ReportTest do
  use ExUnit.Case
  alias Toolshed.Top.Report

  test "erase_report/1 erases" do
    report = Report.erase_report(%{n: 5}) |> IO.iodata_to_binary()
    # there should be 7 new lines
    assert report == "\e[7A\e[2K\n\e[2K\n\e[2K\n\e[2K\n\e[2K\n\e[2K\n\e[2K\n\e[7A"
  end

  test "generate/2 " do
    processes = [
      %{
        application: :kernel,
        delta_heap_size: 376,
        delta_message_queue_len: 0,
        delta_reductions: 121,
        delta_stack_size: 12,
        delta_total_heap_size: 376,
        heap_size: 376,
        message_queue_len: 0,
        name: "logger_proxy",
        pid: "222",
        reductions: 121,
        stack_size: 12,
        total_heap_size: 376
      }
    ]

    assert Report.generate(processes, %{n: 2, order: 2}) |> Enum.join() |> String.replace(" ", "") ==
             "Totalprocesses:1\n\e[36mApplicationNameorPIDReds/ΔMbox/ΔTotal/ΔHeap/ΔStack/Δ\n\e[37mkernellogger_proxy121/1210/0376/376376/37612/12\n"
  end
end
