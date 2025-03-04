# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.CmdTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "cmd/1 can run a program" do
    assert capture_io(fn -> Toolshed.cmd("cat test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"
  end

  test "cmd/1 doesn't crash on invalid UTF-8" do
    # The invalid UTF-8 characters are replaced by � in Elixir 1.16 and later.
    assert capture_io(fn ->
             Toolshed.cmd("echo 'invalid \xFF\xFE utf8'")
           end) =~ ~r/invalid .* utf8/
  end
end
