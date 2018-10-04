defmodule MyHelpers do
  @moduledoc """
  Making the IEx console friendlier one command at a time

  To use the helpers, run:

      iex> use MyHelpers

  Add this to your `.iex.exs` to load automatically.
  """

  defmacro __using__(_) do
    quote do
      import MyHelpers
      use MyHelpers.Top
      use MyHelpers.Nerves
      use MyHelpers.Unix
      use MyHelpers.Net
      use MyHelpers.Misc
      use MyHelpers.HW
      IO.puts("MyHelpers imported. Run h(MyHelpers) for more info")
    end
  end

  @doc """
  Run a command and return the exit code. This function is intended to be run
  interactively.
  """
  @spec cmd(String.t() | charlist()) :: integer()
  def cmd(str) when is_binary(str) do
    {_collectable, exit_code} = System.cmd("sh", ["-c", str], into: IO.stream(:stdio, :line))
    exit_code
  end

  def cmd(str) when is_list(str) do
    str |> to_string |> cmd
  end

  @doc """
  Inspect a value with all integers printed out in hex. This is useful for
  one-off hex conversions. If you're doing a lot of work that requires
  hexadecimal output, you should consider running:

  `IEx.configure(inspect: [base: :hex])`

  The drawback of doing the above is that strings print out as hex binaries.
  """
  @spec hex(integer()) :: String.t()
  def hex(value) do
    inspect(value, base: :hex)
  end
end
