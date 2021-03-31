defmodule ToolshedTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "cmd/1 normal printable chars" do
    assert capture_io(fn ->
             Toolshed.cmd("printf \"hello, world\"")
           end) == "hello, world"
  end

  test "cmd/1 non printable chars" do
    assert capture_io(fn ->
             Toolshed.cmd("printf '\\x0'")
           end) == <<0>>
  end
end
