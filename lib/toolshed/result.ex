defmodule Toolshed.Result do
  @moduledoc """
  Result type for Toolshed helper commands

  All Toolshed commands result values of this type. This lets us do the following:

  1. Support command pipelines
  2. Output something nice for the user at the IEx prompt

  What's the problem, though?

  The default behavior of the IEx REPL is to inspect the return value of the
  function that was called. This makes complete sense for most uses, but it
  also prints strings with embedded newlines with `\\n` characters (same with other escape sequences).
  Most Toolshed commands have output where you really want to see newlines so this
  format is not easy-to-ready at all.

  The solution is to call `IO.write/2` to print the results. This, however, totally
  breaks chaining commands together with Elixir pipes since the result of one command
  can no longer be passed to the next one.

  This fix to this is for all commands to return the `Toolshed.Result` struct. Commands that
  can process results of other commands accept the struct. This has an implementation for
  `Inspect` that expands the `\\n` characters (and everything else) the way that you'd
  expect to make the results easy-to-read.
  """
  defstruct [:result]
  @type t :: %__MODULE__{result: any()}

  @doc """
  Create a new result
  """
  def new(v), do: %__MODULE__{result: v}

  @doc """
  Return the result value
  """
  def v(%__MODULE__{result: v}), do: v

  defimpl Inspect do
    @moduledoc false
    def inspect(result, _opts) do
      pretty(result.result)
    end

    defp pretty(value) when is_atom(value) do
      inspect(value)
    end

    defp pretty(value) do
      to_string(value)
    end
  end
end
