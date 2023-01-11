defmodule Toolshed.LsusbTest do
  use ExUnit.Case

  test "lsusb/0 returns correct value" do
    assert Toolshed.lsusb() == :"do not show this result in output"
  end
end
