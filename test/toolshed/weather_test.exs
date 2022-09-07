defmodule Toolshed.WeatherTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.Weather

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed

    assert capture_io(fn -> h(weather) end) == """
           \e[0m\n\e[7m\e[33m                                 def weather()                                  \e[0m
           \e[0m
             \e[36m@spec\e[0m weather() :: :\"do not show this result in output\"

           Display the local weather
           \e[0m
           See http://wttr.in/:help for more information.
           \e[0m
           """
  end

  test "weather/0 ensures :inets and :ssl are started" do
    Application.stop(:inets)
    Application.stop(:ssl)

    assert weather() == :"do not show this result in output"
  end
end
