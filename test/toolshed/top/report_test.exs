defmodule Toolshed.Top.ReportTest do
  use ExUnit.Case
  alias Toolshed.Top.Report

  test "back/1 erases" do
    data = Report.back_to_the_top(%{rows: 13}) |> IO.chardata_to_string()

    assert data == IO.ANSI.cursor_up(10) <> "\r"
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

    # Create a report, but trim trailing whitespace to avoid issues with editors
    # trimming it in this test.
    report =
      Report.generate(processes, %{rows: 10, columns: 120, order: :reductions})
      |> IO.chardata_to_string()
      |> String.split("\n")
      |> Enum.map(&String.trim_trailing/1)
      |> Enum.join("\n")

    assert report ==
             """
             Total processes: 1
             \e[2K\e[36mApplication  Name or PID                   Reds/Δ      Mbox/Δ     Total/Δ      Heap/Δ     Stack/Δ
             \e[37m\e[2Kkernel       logger_proxy                   121/121       0/0       376/376     376/376      12/12
             """
  end
end
