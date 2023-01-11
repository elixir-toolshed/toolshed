defmodule Toolshed.Core.Date do
  @doc """
  Return the date and time in UTC
  """
  @spec date() :: String.t()
  def date() do
    date_in_unix_format(DateTime.utc_now())
  end

  defp weekday_text(date_time) do
    date_time
    |> DateTime.to_date()
    |> Date.day_of_week()
    |> weekday()
  end

  defp weekday(day_in_number) do
    elem({"", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"}, day_in_number)
  end

  defp month_text(date_time) do
    elem(
      {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"},
      date_time.month
    )
  end

  defp time_text(date_time) do
    date_time
    |> DateTime.to_time()
    |> Time.truncate(:second)
    |> Time.to_string()
  end

  defp format_date(date) when date > 9, do: date
  defp format_date(date), do: " #{date}"

  defp date_in_unix_format(date_time) do
    "#{weekday_text(date_time)} #{month_text(date_time)} #{format_date(date_time.day)} #{time_text(date_time)} UTC #{date_time.year}"
  end
end
