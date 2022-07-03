defmodule Toolshed.HTTPTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "httpget/1 performs a get request on a given url" do
    assert capture_io(fn ->
             Toolshed.httpget(
               "https://raw.githubusercontent.com/elixir-toolshed/toolshed/main/README.md"
             )
           end) =~ "Toolshed aims to improve the Elixir shell"
  end

  test "qr_encode/1 returns correct value" do
    assert Toolshed.qr_encode("Nerves") == :"do not show this result in output"
  end
end
