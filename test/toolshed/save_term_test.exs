defmodule Toolshed.SaveTermTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import :"Elixir.Toolshed.LoadTerm!"
  import :"Elixir.Toolshed.SaveTerm!"

  # Default tmp dir does not work in CI
  @moduletag tmp_dir: System.tmp_dir!()

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(load_term!) end) |> String.match?(~r/def load_term!/)
    assert capture_io(fn -> h(save_term!) end) |> String.match?(~r/def save_term!/)
  end

  test "save_term!/2 saves Elixir term as binary", context do
    path = tmp_file(context.tmp_dir, "binary_data")
    content = {:some_interesting_atom, ["some", "list"]}

    assert save_term!(content, path) == content
    assert load_term!(path) == content
  end

  defp tmp_file(tmp_dir, filename) do
    Path.join(tmp_dir, [to_string(__MODULE__), "-", filename])
  end
end
