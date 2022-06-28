defmodule Toolshed.MiscTest do
  use ExUnit.Case

  @tag :tmp_dir
  test "save_value/2 saves Elixir term as plain text", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "text_data")
    content = {:some_interesting_atom, ["some", "list"]}

    assert Toolshed.Misc.save_value(content, path) == :ok
    assert File.read!(path) == "{:some_interesting_atom, [\"some\", \"list\"]}"
  end

  @tag :tmp_dir
  test "save_term!/2 saves Elixir term as binary", %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "binary_data")
    content = {:some_interesting_atom, ["some", "list"]}

    assert Toolshed.Misc.save_term!(content, path) == content
    assert Toolshed.Misc.load_term!(path) == content
  end
end
