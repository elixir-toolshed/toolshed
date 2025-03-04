# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.NetTest do
  use ExUnit.Case

  test "ifconfig/0 returns correct value" do
    assert Toolshed.ifconfig() == :"do not show this result in output"
  end
end
