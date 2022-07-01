defmodule Toolshed.NetTest do
  use ExUnit.Case
  import Toolshed.Ifconfig

  test "ifconfig/0 returns correct value" do
    assert ifconfig() == :"do not show this result in output"
  end
end
