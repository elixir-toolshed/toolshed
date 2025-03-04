# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.GrepTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "grep/2 returns lines of file with given pattern" do
    assert capture_io(fn -> Toolshed.grep(~r/Content/, "test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"

    assert capture_io(fn -> Toolshed.grep(~r/not available/, "test/support/test_file.doc") end) ==
             ""
  end
end
