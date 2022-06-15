defmodule Toolshed.DateTest do
  use ExUnit.Case

  test "date/0 returns current date in unix format" do
    # There's a race condition on the time that's returned between the
    # two date functions if we catch the seconds changing.

    expected1 = unix_date_output()
    actual = Toolshed.Date.date()
    expected2 = unix_date_output()

    assert actual == expected1 or actual == expected2
  end

  defp unix_date_output() do
    {date_time, 0} = System.cmd("date", ["-u"], env: %{"LC_ALL" => "C"})
    String.trim(date_time)
  end
end
