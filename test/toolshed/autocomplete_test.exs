defmodule Toolshed.AutocompleteTest do
  use ExUnit.Case
  alias Toolshed.Autocomplete

  defp sf(string) do
    string |> to_charlist() |> Enum.reverse() |> Autocomplete.string_fragment()
  end

  describe "triggers on string fragments" do
    test "ignores empty strings" do
      assert sf('') == ''
      assert sf('"') == ''
    end

    test "ignores things that aren't strings" do
      assert sf('abc') == ''
    end

    test "triggers on possible strings" do
      assert sf('"abc') == 'abc'
      assert sf('"escaped \\" quote') == 'escaped \\" quote'
      assert sf('File.read("abc') == 'abc'
      assert sf('File.read("ABCabc123.___') == 'ABCabc123.___'
      assert sf('File.read("some_file", var') == ''
      assert sf('File.read("some_file", "string') == 'string'
    end

    test "ignores string interpolation" do
      assert sf('"\#{') == ''
      assert sf('"\#{Fi') == ''
    end
  end

  describe "find_possible_paths/1" do
    test "existing absolute paths" do
      # /usr is a directory in / on OSX and Linux
      assert {"/usr", true} in Autocomplete.find_possible_paths("/")

      # partial entry
      assert {"/usr", true} in Autocomplete.find_possible_paths("/u")
      assert {"/usr", true} in Autocomplete.find_possible_paths("/us")
      assert {"/usr", true} in Autocomplete.find_possible_paths("/usr")
      assert {"/usr/bin", true} in Autocomplete.find_possible_paths("/usr/")
      assert {"/usr/bin", true} in Autocomplete.find_possible_paths("/usr/b")
      assert {"/usr/bin", true} in Autocomplete.find_possible_paths("/usr/bi")
      assert {"/usr/bin", true} in Autocomplete.find_possible_paths("/usr/bin")
    end

    test "bad absolute paths" do
      assert [] == Autocomplete.find_possible_paths("/nonexistent_dir")
    end

    test "dot" do
      paths = Autocomplete.find_possible_paths(".")

      assert {".", true} in paths
      assert {"..", true} in paths
      assert {".formatter.exs", false} in paths
    end

    test "dot dot" do
      assert [{"..", true}] == Autocomplete.find_possible_paths("..")
    end

    test "relative paths with the dot" do
      assert {"./lib", true} in Autocomplete.find_possible_paths("./")
      assert {"./lib", true} in Autocomplete.find_possible_paths("./l")
      assert {"./lib", true} in Autocomplete.find_possible_paths("./li")
      assert {"./lib", true} in Autocomplete.find_possible_paths("./lib")
      assert {"./lib/toolshed.ex", false} in Autocomplete.find_possible_paths("./lib/")
      assert {"./lib/toolshed.ex", false} in Autocomplete.find_possible_paths("./lib/t")
      assert {"./lib/toolshed", true} in Autocomplete.find_possible_paths("./lib/t")

      assert [] == Autocomplete.find_possible_paths("./lib/ttt")
    end

    test "relative paths without the dot" do
      assert {"lib", true} in Autocomplete.find_possible_paths("l")
      assert {"lib", true} in Autocomplete.find_possible_paths("li")
      assert {"lib", true} in Autocomplete.find_possible_paths("lib")
      assert {"lib/toolshed", true} in Autocomplete.find_possible_paths("lib/")
    end

    test "ignores strings with wildcard chars" do
      # Path.wildcard/2 is used in the implementation and we don't
      # want to trigger full subdirectory traversals on path completion.
      assert [] == Autocomplete.find_possible_paths("*")
      assert [] == Autocomplete.find_possible_paths("/etc/*")
      assert [] == Autocomplete.find_possible_paths("?i")
      assert [] == Autocomplete.find_possible_paths("l[a-z]b")
      assert [] == Autocomplete.find_possible_paths("{lib,test}")
    end
  end

  describe "expand_path/2" do
    test "expands to no options" do
      assert {:no, [], []} == Autocomplete.expand_path("zzz", [])
    end

    test "expands to one option" do
      # file expands to final double quote
      assert {:yes, '23"', []} == Autocomplete.expand_path("1", [{"123", false}])

      # directory expands to include slash
      assert {:yes, '23/', []} == Autocomplete.expand_path("1", [{"123", true}])
    end

    test "expands to hint and options" do
      assert {:yes, 'bc', ['abcd', 'abce', 'abcf']} ==
               Autocomplete.expand_path("a", [{"abcd", false}, {"abce", true}, {"abcf", false}])
    end
  end
end
