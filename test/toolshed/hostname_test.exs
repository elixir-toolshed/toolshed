# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.HostnameTest do
  use ExUnit.Case

  test "hostname/0 returns correct value" do
    assert Toolshed.hostname() |> is_binary()
  end
end
