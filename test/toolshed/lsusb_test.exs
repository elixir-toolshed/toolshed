defmodule Toolshed.LsusbTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Lsusb

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(lsusb) end) |> String.match?(~r/def lsusb/)
  end

  test "lsusb/0 returns correct value" do
    assert lsusb() == :"do not show this result in output"
  end
end
