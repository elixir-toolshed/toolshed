defmodule Toolshed.CatTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Cat

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(cat) end) |> String.match?(~r/def cat\(path\)/)
  end

  test "cat/1 reads file content" do
    assert capture_io(fn -> cat("test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"
  end
end
