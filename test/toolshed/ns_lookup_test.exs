defmodule Toolshed.NslookupTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Nslookup

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(nslookup) end) |> String.match?(~r/def nslookup/)
  end

  test "nslookup/1 returns correct value" do
    assert nslookup("google.com") == :"do not show this result in output"
  end
end
