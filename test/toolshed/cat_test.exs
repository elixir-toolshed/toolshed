defmodule Toolshed.CatTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Cat

  test "cat/1 reads file content" do
    assert capture_io(fn -> cat("test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"
  end
end
