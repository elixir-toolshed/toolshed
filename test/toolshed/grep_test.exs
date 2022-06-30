defmodule Toolshed.GrepTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Grep

  test "grep/2 returns lines of file with given pattern" do
    assert capture_io(fn -> grep(~r/Content/, "test/support/test_file.doc") end) ==
             "\e[31mContent\e[0m of this will be read for test purposes"

    assert capture_io(fn -> grep(~r/not available/, "test/support/test_file.doc") end) ==
             ""
  end
end
