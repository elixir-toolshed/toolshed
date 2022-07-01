defmodule Toolshed.NslookupTest do
  use ExUnit.Case
  import Toolshed.Nslookup

  test "nslookup/1 returns correct value" do
    assert nslookup("google.com") == :"do not show this result in output"
  end
end
