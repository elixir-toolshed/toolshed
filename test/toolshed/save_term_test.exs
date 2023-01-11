defmodule Toolshed.SaveTermTest do
  use ExUnit.Case

  # Default tmp dir does not work in CI
  @moduletag tmp_dir: System.tmp_dir!()

  test "save_term!/2 saves Elixir term as binary", context do
    path = tmp_file(context.tmp_dir, "binary_data")
    content = {:some_interesting_atom, ["some", "list"]}

    assert Toolshed.save_term!(content, path) == content
    assert Toolshed.load_term!(path) == content
  end

  defp tmp_file(tmp_dir, filename) do
    Path.join(tmp_dir, [to_string(__MODULE__), "-", filename])
  end
end
