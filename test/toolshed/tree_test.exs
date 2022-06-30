defmodule Toolshed.TreeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Tree

  test "tree/1 prints directories and files in tree form" do
    assert capture_io(fn -> tree("test/support") end) ==
             "test/support\n└── test_file.doc\n"
  end
end
