defmodule Toolshed.NetTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Ifconfig

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(ifconfig) end) |> String.match?(~r/def ifconfig/)
  end

  test "ifconfig/0 returns correct value" do
    assert ifconfig() == :"do not show this result in output"
  end
end
