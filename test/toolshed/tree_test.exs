# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.TreeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "tree/1 prints directories and files in tree form" do
    assert capture_io(fn -> Toolshed.tree("test/support") end) ==
             "test/support\n└── test_file.doc\n"
  end
end
