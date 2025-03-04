# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.LsofTest do
  use ExUnit.Case

  test "lsof/0 returns correct value" do
    assert Toolshed.lsof() == :ok
  end
end
