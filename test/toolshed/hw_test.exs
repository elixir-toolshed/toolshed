defmodule Toolshed.HWTest do
  use ExUnit.Case

  test "lsusb/0 returns correct value" do
    assert Toolshed.HW.lsusb() == :"do not show this result in output"
  end
end
