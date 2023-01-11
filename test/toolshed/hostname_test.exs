defmodule Toolshed.HostnameTest do
  use ExUnit.Case

  test "hostname/0 returns correct value" do
    assert Toolshed.hostname() |> is_binary()
  end
end
