# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.LsusbTest do
  use ExUnit.Case

  test "lsusb/0 returns correct value" do
    assert Toolshed.lsusb() == :"do not show this result in output"
  end
end
