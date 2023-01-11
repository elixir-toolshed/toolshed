defmodule Toolshed.Core.SaveValue do
  @doc """
  Save a value to a file as Elixir terms

  ## Examples

      # Save the contents of SystemRegistry to a file
      iex> SystemRegistry.match(:_) |> save_value("/root/sr.txt")
      :ok
  """
  @spec save_value(any(), Path.t(), keyword()) :: :ok | {:error, File.posix()}
  def save_value(value, path, inspect_opts \\ []) do
    opts =
      Keyword.merge([pretty: true, limit: :infinity, printable_limit: :infinity], inspect_opts)

    contents = inspect(value, opts)
    File.write(path, contents)
  end
end
