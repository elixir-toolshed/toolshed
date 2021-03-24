defmodule ToolshedTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "cmd/1 normal printable chars" do
    assert capture_io(fn ->
             Toolshed.cmd("echo \"hello, world\"")
           end) == "hello, world\n"
  end

  test "cmd/1 non printable chars" do
    assert capture_io(fn ->
             Toolshed.cmd("echo -e -n '\\x0'")
           end) == <<0>>
  end
end
