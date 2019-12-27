defmodule Toolshed.Unix do
  @moduledoc """
  Helpers for when your fingers are too used to typing Unix
  commands.

  Helpers include:

   * `cat/1`   - print out a file
   * `grep/2`  - print out lines of a file that match a regular expression
   * `tree/1`  - print out a directory tree
   * `uptime/0` - print the update of the Erlang VM

  """

  alias Toolshed.Result

  @doc """
  Reads and prints out the contents of a file
  """
  @spec cat(Path.t()) :: Result.t()
  def cat(path) do
    path
    |> File.read!()
    |> Result.new()
  end

  @doc """
  Run a regular expression on a file and print the matching lines.

  ```elixir
  iex> cat("/etc/services") |> grep(~r/ntp/)
  ntp             123/tcp     # Network Time Protocol
  ```

  If colored is enabled for the shell, the matches will be highlighted red.
  """
  @spec grep(Result.t() | String.t(), Regex.t()) :: Result.t()
  def grep(%Result{} = result, regex) do
    result
    |> Result.v()
    |> to_string()
    |> grep(regex)
  end

  def grep(s, regex) when is_binary(s) do
    s
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(regex, &1))
    |> Enum.map(fn line ->
      Regex.replace(regex, line, &IO.ANSI.format([:red, &1]))
    end)
    |> Enum.intersperse("\n")
    |> Result.new()
  end

  @doc """
  Print out directories and files in tree form.
  """
  @spec tree(Path.t()) :: Result.t()
  def tree(path \\ ".") do
    case file_info(path, path) do
      {:directory, _} ->
        [path, ?\n, do_tree("", path, files(path))]

      _ ->
        path
    end
    |> Result.new()
  end

  defp do_tree(_prefix, _dir, []), do: []

  defp do_tree(prefix, dir, [{:directory, filename} | rest]) do
    path = Path.join(dir, filename)

    [
      puts_tree_branch(prefix, filename, rest),
      do_tree([prefix, tree_trunk(rest)], path, files(path)),
      do_tree(prefix, dir, rest)
    ]
  end

  defp do_tree(prefix, dir, [{_type, filename} | rest]) do
    [puts_tree_branch(prefix, filename, rest), do_tree(prefix, dir, rest)]
  end

  defp puts_tree_branch(prefix, filename, rest) do
    [prefix, tree_branch(rest), filename, ?\n]
  end

  defp tree_branch([]), do: "└── "
  defp tree_branch(_), do: "├── "

  defp tree_trunk([]), do: "    "
  defp tree_trunk(_), do: "│   "

  defp files(dir) do
    File.ls!(dir)
    |> Enum.map(&file_info(Path.join(dir, &1), &1))
  end

  defp file_info(path, name) do
    stat = File.lstat!(path)
    {stat.type, name}
  end

  @doc """
  Print out the current uptime.
  """
  @spec uptime() :: Result.t()
  def uptime() do
    {uptime_millis, _} = :erlang.statistics(:wall_clock)

    uptime_seconds = div(uptime_millis, 1000)

    daystime = :calendar.seconds_to_daystime(uptime_seconds)

    [
      format(:days, daystime),
      format(:hours, daystime),
      format(:minutes, daystime),
      format(:seconds, daystime)
    ]
    |> Result.new()
  end

  defp format(:days, {days, _rest}) when days > 0, do: [to_string(days), " days, "]

  defp format(:hours, {days, {hours, _minutes, _seconds}}) when days > 0 or hours > 0,
    do: [to_string(hours), " hours, "]

  defp format(:minutes, {days, {hours, minutes, _seconds}})
       when days > 0 or hours > 0 or minutes > 0,
       do: [to_string(minutes), " minutes and "]

  defp format(:seconds, {_days, {_hours, _minutes, seconds}}),
    do: [to_string(seconds), " seconds"]

  defp format(_else, _data), do: []

  @doc """
  Print out the date similar to the Unix date command
  """
  @spec date() :: Result.t()
  def date() do
    dt = DateTime.utc_now()

    Result.new("#{weekday_text(dt)} #{month_text(dt)} #{dt.day} #{time_text(dt)} UTC #{dt.year}")
  end

  defp weekday_text(dt) do
    day_index = dt |> DateTime.to_date() |> Date.day_of_week()

    elem(
      {"", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"},
      day_index
    )
  end

  defp month_text(dt) do
    elem(
      {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"},
      dt.month
    )
  end

  defp time_text(dt) do
    dt
    |> DateTime.to_time()
    |> Time.truncate(:second)
    |> Time.to_string()
  end
end
