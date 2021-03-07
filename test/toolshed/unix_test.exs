defmodule Toolshed.UnixTest do
  use ExUnit.Case
  alias Toolshed.Unix

  test "date/0 returns current date in unix format" do
    assert Unix.date() == unix_date_output()
  end

  defp unix_date_output do
    {date_time, 0} = System.cmd("date", ["-u"], env: %{"LC_ALL" => "C"})
    String.trim(date_time)
  end
end
