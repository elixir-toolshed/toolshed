defmodule Toolshed.Tree do
  @moduledoc false

  @type filetype :: :device | :directory | :other | :regular | :symlink
  @type filename :: binary

  @spec do_tree(iodata, binary, [{filetype, filename}]) :: :ok
  def do_tree(_prefix, _dir, []), do: :ok

  def do_tree(prefix, dir, [{:directory, filename} | rest]) do
    puts_tree_branch(prefix, filename, rest)

    path = Path.join(dir, filename)
    do_tree([prefix, tree_trunk(rest)], path, files(path))
    do_tree(prefix, dir, rest)
  end

  def do_tree(prefix, dir, [{_type, filename} | rest]) do
    puts_tree_branch(prefix, filename, rest)
    do_tree(prefix, dir, rest)
  end

  @spec files(binary) :: [{filetype, filename}]
  def files(dir) do
    File.ls!(dir)
    |> Enum.map(&file_info(Path.join(dir, &1), &1))
  end

  @spec file_info(Path.t(), binary) :: {filetype, filename}
  def file_info(path, name) do
    stat = File.lstat!(path)
    {stat.type, name}
  end

  defp puts_tree_branch(prefix, filename, rest) do
    IO.puts([prefix, tree_branch(rest), filename])
  end

  defp tree_branch([]), do: "└── "
  defp tree_branch(_), do: "├── "

  defp tree_trunk([]), do: "    "
  defp tree_trunk(_), do: "│   "
end
