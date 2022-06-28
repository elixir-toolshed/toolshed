defmodule Toolshed.NetTest do
  use ExUnit.Case

  test "hostname/0 returns correct value" do
    assert Toolshed.Net.hostname() |> is_binary()
  end

  test "nslookup/1 returns correct value" do
    assert Toolshed.Net.nslookup("google.com") == :"do not show this result in output"
  end

  test "ifconfig/0 returns correct value" do
    assert Toolshed.Net.ifconfig() == :"do not show this result in output"
  end
end
