defmodule Toolshed.LsofTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(lsof) end) |> String.match?(~r/def lsof/)
  end

  test "lsof/0 returns correct value" do
    assert Toolshed.Lsof.lsof() == :ok
  end
end
