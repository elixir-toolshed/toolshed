defmodule Toolshed.Core.Tree do
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
