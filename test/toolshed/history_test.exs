defmodule Toolshed.HistoryTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "history can print out commandline history" do
    # Use this process as a fake group leader
    Process.put(
      :line_buffer,
      ['Fourth command\n', 'Third command\n', 'Second command\n', 'First command\n']
    )

    fake_gl = self()

    output = capture_io(fn -> Toolshed.history(fake_gl) end)

    assert output == """
           1  First command
           2  Second command
           3  Third command
           4  Fourth command

           """
  end
end
