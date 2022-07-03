defmodule Toolshed.NetTest do
  use ExUnit.Case

  test "ifconfig/0 returns correct value" do
    assert Toolshed.ifconfig() == :"do not show this result in output"
  end
end
