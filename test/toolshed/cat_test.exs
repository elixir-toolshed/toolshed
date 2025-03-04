# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.CatTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "cat/1 reads file content" do
    assert capture_io(fn -> Toolshed.cat("test/support/test_file.doc") end) ==
             "Content of this will be read for test purposes"
  end
end
