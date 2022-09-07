defmodule Toolshed.HostnameTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Hostname

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(hostname) end) |> String.match?(~r/def hostname/)
  end

  test "hostname/0 returns correct value" do
    assert hostname() |> is_binary()
  end
end
