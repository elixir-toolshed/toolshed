defmodule Toolshed.Core.SaveTerm do
  @doc """
  Save an Erlang term to the filesystem for easy loading later

  This function returns the `value` passed in to allow easy piping.

  ## Examples

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
end
