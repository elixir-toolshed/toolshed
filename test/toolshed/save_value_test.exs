defmodule Toolshed.SaveValueTest do
  use ExUnit.Case

  # Default tmp dir does not work in CI
  @moduletag tmp_dir: System.tmp_dir!()

  test "save_value/2 saves Elixir term as plain text", context do
    path = tmp_file(context.tmp_dir, "text_data")
    content = {:some_interesting_atom, ["some", "list"]}

    assert Toolshed.save_value(content, path) == :ok
    assert File.read!(path) == "{:some_interesting_atom, [\"some\", \"list\"]}"
  end

  defp tmp_file(tmp_dir, filename) do
    Path.join(tmp_dir, [to_string(__MODULE__), "-", filename])
  end
end
