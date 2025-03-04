# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.NslookupTest do
  use ExUnit.Case

  test "nslookup/1 returns correct value" do
    assert Toolshed.nslookup("google.com") == :"do not show this result in output"
  end
end
