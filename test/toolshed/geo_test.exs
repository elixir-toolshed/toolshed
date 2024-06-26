defmodule Toolshed.GeoTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "geo/1 returns at least the time" do
    # Everything else is optional unfortunately
    assert capture_io(&Toolshed.geo/0) =~ "UTC Time  : "
  end

  test "geo/1 supports overriding the server" do
    assert capture_io(fn ->
             Toolshed.geo(whenwhere_url: "http://not_a_server.nerves-project.org")
           end) =~ "Something went wrong when making an HTTP request"
  end
end
