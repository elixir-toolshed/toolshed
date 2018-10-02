defmodule MyHelpersTest do
  use ExUnit.Case
  doctest MyHelpers

  test "greets the world" do
    assert MyHelpers.hello() == :world
  end
end
