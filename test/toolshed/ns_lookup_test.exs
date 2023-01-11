defmodule Toolshed.NslookupTest do
  use ExUnit.Case

  test "nslookup/1 returns correct value" do
    assert Toolshed.nslookup("google.com") == :"do not show this result in output"
  end
end
