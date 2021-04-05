defmodule Toolshed.UnixTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Toolshed.Unix

  test "date/0 returns current date in unix format" do
    # There's a race condition on the time that's returned between the
    # two date functions if we catch the seconds changing.

    expected1 = unix_date_output()
    actual = Unix.date()
    expected2 = unix_date_output()

    assert actual == expected1 or actual == expected2
  end

  defp unix_date_output do
    {date_time, 0} = System.cmd("date", ["-u"], env: %{"LC_ALL" => "C"})
    String.trim(date_time)
  end

  test "cat/1 reads file content" do
    assert capture_io(fn -> Unix.cat("test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"
  end

  test "tree/1 prints directories and files in tree form" do
    assert capture_io(fn -> Unix.tree("test/support") end) == "test/support\n└── test_file.doc\n"
  end

  test "grep/2 returns lines of file with given pattern" do
    assert capture_io(fn -> Unix.grep(~r/Content/, "test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"

    assert capture_io(fn -> Unix.grep(~r/not available/, "test/support/test_file.doc") end) ==
             ""
  end

  test "uptime/0 return current uptime" do
    output = capture_io(&Unix.uptime/0)
    assert String.length(output) > 0
    assert String.ends_with?(output, "\n")
  end
end
