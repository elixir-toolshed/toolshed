defmodule Toolshed.Misc do
  @moduledoc """
  Miscellaneous helpers
  """

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

  @doc """
  Save an Erlang term to the filesystem for easy loading later

  This function returns the `value` passed in to allow easy piping.

  ## Examples
  #
      iex> :sys.get_state(MyServer) |> save_term!("/root/my_server.term")
      # Reboot board
      iex> :sys.replace_state(&load_term!("/root/my_server.term"))
  """
  @spec save_term!(term, Path.t()) :: term()
  def save_term!(value, path) do
    term = :erlang.term_to_binary(value)
    :ok = File.write!(path, term)
    value
  end

  @doc """
  Load an Erlang term from the filesystem.

  ## Examples
  #
      iex> save_term!({:some_interesting_atom, ["some", "list"]}, "/root/some_atom.term")
      {:some_interesting_atom, ["some", "list"]}
      iex> load_term!("/root/some_atom.term")
      {:some_interesting_atom, ["some", "list"]}
  """
  @spec load_term!(Path.t()) :: term()
  def load_term!(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
