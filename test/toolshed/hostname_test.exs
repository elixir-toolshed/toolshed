defmodule Toolshed.HostnameTest do
  use ExUnit.Case
  import Toolshed.Hostname

  test "hostname/0 returns correct value" do
    assert hostname() |> is_binary()
  end
end
