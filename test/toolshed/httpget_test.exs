# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.HttpgetTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "httpget/1 performs a get request on a given url" do
    assert capture_io(fn ->
             Toolshed.httpget(
               "https://raw.githubusercontent.com/elixir-toolshed/toolshed/main/README.md"
             )
           end) =~ "Toolshed improves the Elixir shell"
  end
end
