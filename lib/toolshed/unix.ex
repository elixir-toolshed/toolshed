defmodule Toolshed.Unix do
  @moduledoc """
  Helpers for when your fingers are too used to typing Unix
  commands.

  Helpers include:

   * `cat/1`   - print out a file
   * `date/0`  - print out the current date and time
   * `grep/2`  - print out lines of a file that match a regular expression
   * `tree/1`  - print out a directory tree
   * `uptime/0` - print the update of the Erlang VM

  """

  @doc """
  Reads and prints out the contents of a file
  """
  @spec cat(Path.t()) :: :"do not show this result in output"
  def cat(path) do
    path
    |> File.read!()
    |> IO.write()

    IEx.dont_display_result()
  end

  @doc """
  Run a regular expression on a file and print the matching lines.

  iex> grep ~r/video/, "/etc/mime.types"
  """
  @spec grep(Regex.t(), Path.t()) :: :"do not show this result in output"
  def grep(regex, path) do
    File.stream!(path)
    |> Stream.filter(&Regex.match?(regex, &1))
    |> Stream.each(&IO.write/1)
    |> Stream.run()

    IEx.dont_display_result()
  end

  @doc """
  Print out directories and files in tree form.
  """
  @spec tree(Path.t()) :: :"do not show this result in output"
  def tree(path \\ ".") do
    IO.puts(path)

    case file_info(path, path) do
      {:directory, _} ->
        do_tree("", path, files(path))

      _ ->
        :ok
    end

    IEx.dont_display_result()
  end

  @doc """
  Print out the current uptime.
  """
  @spec uptime() :: :"do not show this result in output"
  def uptime() do
    :c.uptime()
    IEx.dont_display_result()
  end

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
    "#{weekday_text(date_time)} #{month_text(date_time)} #{format_date(date_time.day)} #{
      time_text(date_time)
    } UTC #{date_time.year}"
  end

  defp do_tree(_prefix, _dir, []), do: :ok

  defp do_tree(prefix, dir, [{:directory, filename} | rest]) do
    puts_tree_branch(prefix, filename, rest)

    path = Path.join(dir, filename)
    do_tree([prefix, tree_trunk(rest)], path, files(path))
    do_tree(prefix, dir, rest)
  end

  defp do_tree(prefix, dir, [{_type, filename} | rest]) do
    puts_tree_branch(prefix, filename, rest)
    do_tree(prefix, dir, rest)
  end

  defp puts_tree_branch(prefix, filename, rest) do
    IO.puts([prefix, tree_branch(rest), filename])
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
end
