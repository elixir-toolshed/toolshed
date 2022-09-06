defmodule Toolshed.HttpgetTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Httpget

  test "httpget/1 performs a get request on a given url" do
    assert capture_io(fn ->
             httpget("https://raw.githubusercontent.com/elixir-toolshed/toolshed/main/README.md")
           end) =~ "Toolshed aims to improve the Elixir shell"
  end
end
