defmodule Toolshed.WeatherTest do
  use ExUnit.Case

  test "weather/0 ensures :inets and :ssl are started" do
    Application.stop(:inets)
    Application.stop(:ssl)

    assert Toolshed.weather() == :"do not show this result in output"
  end
end
