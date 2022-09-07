defmodule Toolshed.TreeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Tree

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(tree) end) |> String.match?(~r/def tree/)
  end

  test "tree/1 prints directories and files in tree form" do
    assert capture_io(fn -> tree("test/support") end) ==
             "test/support\n└── test_file.doc\n"
  end
end
