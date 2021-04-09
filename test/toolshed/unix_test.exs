defmodule Toolshed.UnixTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Toolshed.Unix

  test "cat/1 reads file content" do
    assert capture_io(fn -> Unix.cat("test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"
  end

  test "tree/1 prints directories and files in tree form" do
    assert capture_io(fn -> Unix.tree("test/support") end) == "test/support\n└── test_file.doc\n"
  end

  test "grep/2 returns lines of file with given pattern" do
    assert capture_io(fn -> Unix.grep(~r/Content/, "test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"

    assert capture_io(fn -> Unix.grep(~r/not available/, "test/support/test_file.doc") end) ==
             ""
  end

  test "uptime/0 return current uptime" do
    output = capture_io(&Unix.uptime/0)
    assert String.length(output) > 0
    assert String.ends_with?(output, "\n")
  end
end
