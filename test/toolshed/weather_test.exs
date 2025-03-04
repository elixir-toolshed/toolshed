# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.WeatherTest do
  use ExUnit.Case

  @tag :weather
  test "weather/0 ensures :inets and :ssl are started" do
    Application.stop(:inets)
    Application.stop(:ssl)

    assert Toolshed.weather() == :"do not show this result in output"
  end
end
