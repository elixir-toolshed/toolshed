defmodule MyHelpers.Unix do
  @moduledoc """
  Helpers for when your fingers are too used to typing Unix
  commands.

  Helpers include:

   * `dmesg/0`   - print kernel messages
   * `reboot/0`  - reboots gracefully
   * `reboot!/0` - reboots immediately
  """

  defmacro __using__(_) do
    quote do
      import MyHelpers.Unix
    end
  end

  @doc """
  Print out a file
  """
  @spec cat(String.t()) :: :"do not show this result in output"
  def cat(path) do
    File.read!(path) |> IO.puts()
    IEx.dont_display_result()
  end

  @doc """
  Run a regular expression on a file and print the matching lines.

  iex> grep ~r/video/, "/etc/mime.types"
  """
  @spec grep(Regex.t(), String.t()) :: :"do not show this result in output"
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
