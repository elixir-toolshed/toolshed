defmodule Toolshed.HTTPTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Toolshed.HTTP

  test "httpget/1 performs a get request on a given url" do
    assert capture_io(fn ->
             HTTP.httpget(
               "https://raw.githubusercontent.com/elixir-toolshed/toolshed/main/README.md"
             )
           end) =~ "Toolshed aims to improve the Elixir shell"
  end

  test "weather/0 returns correct value" do
    assert Toolshed.HTTP.weather() == :"do not show this result in output"
  end

  test "qr_encode/1 returns correct value" do
    assert Toolshed.HTTP.qr_encode("Nerves") == :"do not show this result in output"
  end
end
