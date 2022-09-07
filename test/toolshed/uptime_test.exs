defmodule Toolshed.UptimeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Uptime

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(uptime) end) |> String.match?(~r/def uptime/)
  end

  test "uptime/0 return current uptime" do
    output = capture_io(&uptime/0)
    assert String.length(output) > 0
    assert String.ends_with?(output, "\n")
  end
end
