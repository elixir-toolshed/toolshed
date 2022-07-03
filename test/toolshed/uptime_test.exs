defmodule Toolshed.UptimeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "uptime/0 return current uptime" do
    output = capture_io(&Toolshed.uptime/0)
    assert String.length(output) > 0
    assert String.ends_with?(output, "\n")
  end
end
