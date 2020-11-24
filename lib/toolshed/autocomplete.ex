defmodule Toolshed.Autocomplete do
  @moduledoc """
  Add path completion to the default IEx autocompletion

  This modules augments the IEx autocompletion logic to complete file paths in
  strings. This lets you tab the paths in calls to Toolshed helpers and
  functions like `File.read/1`.
  """

  @type result() :: {:yes | :no, charlist(), [charlist()]}

  @doc """
  Handle autocomplete calls

  This function handles path autocompletion and if that's not appropriate, it
  delegates to IEx.Autocomplete for normal completion.

  See `set_expand_fun/0` for manual registration.
  """
  @spec expand(charlist()) :: result()
  def expand(expr) do
    case string_fragment(expr) do
      [] ->
        IEx.Autocomplete.expand(expr)

      fragment_cl ->
        fragment = to_string(fragment_cl)
        possible_paths = find_possible_paths(fragment)
        expand_path(fragment, possible_paths)
    end
  end

  @doc false
  @spec string_fragment(charlist()) :: charlist()
  def string_fragment(expr), do: string_fragment(:possible_string, expr, [])
  defp string_fragment(:assume_not_string, [], acc), do: acc

  defp string_fragment(:assume_not_string, [?" | rest], acc),
    do: string_fragment(:assume_string, rest, acc)

  defp string_fragment(:assume_not_string, [_ | rest], acc),
    do: string_fragment(:assume_not_string, rest, acc)

  defp string_fragment(:assume_string, [], _acc), do: []

  defp string_fragment(:assume_string, [?" | rest], acc),
    do: string_fragment(:assume_not_string, rest, acc)

  defp string_fragment(:assume_string, [_ | rest], acc),
    do: string_fragment(:assume_string, rest, acc)

  defp string_fragment(:possible_string, [], _acc), do: []

  # Handle escaped double quotes
  defp string_fragment(:possible_string, [?", ?\\ | rest], acc) do
    string_fragment(:possible_string, rest, [?\\, ?" | acc])
  end

  defp string_fragment(:possible_string, [?" | rest], acc) do
    string_fragment(:assume_not_string, rest, acc)
  end

  defp string_fragment(:possible_string, [h | rest], acc) do
    string_fragment(:possible_string, rest, [h | acc])
  end

  defp completion_part(already_entered, full_path, dir?) do
    part = full_path |> String.replace_prefix(already_entered, "") |> to_charlist()

    if dir? do
      part ++ '/'
    else
      part ++ '"'
    end
  end

  # Returns possible paths as [{path, dir?}]
  @doc false
  @spec find_possible_paths(String.t()) :: [{Path.t(), boolean}]
  def find_possible_paths(path_fragment) do
    dir = Path.dirname(path_fragment)

    case File.ls(dir) do
      {:ok, files} ->
        files
        |> Enum.map(&Path.join(dir, &1))
        |> Enum.filter(&String.starts_with?(&1, path_fragment))
        |> Enum.map(fn path -> {path, File.dir?(path)} end)

      _ ->
        []
    end
  end

  # Look through a list of possible paths for the specified
  # fragment and return a completion hint and options
  @doc false
  @spec expand_path(String.t(), [{Path.t(), boolean()}]) ::
          {:no, [], []} | {:yes, charlist(), [charlist()]}
  def expand_path(path_fragment, possible_paths) do
    expansions =
      Enum.map(possible_paths, fn {path, dir?} ->
        {completion_part(path_fragment, path, dir?), to_charlist(Path.basename(path))}
      end)

    case expansions do
      [] ->
        {:no, '', []}

      [{unique, _}] ->
        {:yes, unique, []}

      list ->
        {completions, filenames} = Enum.unzip(list)
        hint = Enum.reduce(completions, &common_prefix/2)
        {:yes, hint, filenames}
    end
  end

  # Find the common prefix for two charlists
  defp common_prefix(a, b, acc \\ [])

  defp common_prefix([h | t1], [h | t2], acc) do
    common_prefix(t1, t2, [h | acc])
  end

  defp common_prefix(_, _, acc) do
    Enum.reverse(acc)
  end

  # The following are adapted from IEx.Autocomplete

  # Provides a helper function that is injected into connecting remote nodes to
  # properly handle autocompletion.
  @doc false
  @spec remsh(node()) :: (charlist() -> result())
  def remsh(node) do
    fn e ->
      case :rpc.call(node, Toolshed.Autocomplete, :expand, [e]) do
        {:badrpc, _} -> {:no, '', []}
        r -> r
      end
    end
  end

  @doc """
  Set the IO server's `:expand_fun`

  This is a slightly modified version of `IEx.Autocomplete.set_expand_fun/0` to
  register the autocompletion logic. It is normally called by `use Toolshed`,
  but may be called manually as well.
  """
  @spec set_expand_fun() :: :ok | {:error, any}
  def set_expand_fun() do
    gl = Process.group_leader()

    expand_fun =
      if node(gl) != node() do
        Toolshed.Autocomplete.remsh(node())
      else
        &Toolshed.Autocomplete.expand/1
      end

    # expand_fun is not supported by a shell variant
    # on Windows, so we do two IO calls, not caring
    # about the result of the expand_fun one.
    _ = :io.setopts(gl, expand_fun: expand_fun)
    :io.setopts(gl, binary: true, encoding: :unicode)
  end
end
