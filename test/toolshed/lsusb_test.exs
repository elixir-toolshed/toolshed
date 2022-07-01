defmodule Toolshed.LsusbTest do
  use ExUnit.Case
  import Toolshed.Lsusb

  test "lsusb/0 returns correct value" do
    assert lsusb() == :"do not show this result in output"
  end
end
