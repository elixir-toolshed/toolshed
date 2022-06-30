defmodule Toolshed.UptimeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Uptime

  test "uptime/0 return current uptime" do
    output = capture_io(&uptime/0)
    assert String.length(output) > 0
    assert String.ends_with?(output, "\n")
  end
end
