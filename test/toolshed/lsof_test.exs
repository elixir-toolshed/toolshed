defmodule Toolshed.LsofTest do
  use ExUnit.Case

  test "lsof/0 returns correct value" do
    assert Toolshed.lsof() == :ok
  end
end
