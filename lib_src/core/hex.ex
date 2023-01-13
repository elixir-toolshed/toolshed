defmodule Toolshed.Core.Hex do
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
