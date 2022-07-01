defmodule Toolshed.Hostname do
  @moduledoc """
  This module provides the `hostname` command
  """

  require Record

  @doc """
  Return the hostname

  ## Examples

      iex> hostname
      "nerves-1234"
  """
  @spec hostname() :: String.t()
  def hostname() do
    {:ok, hostname_charlist} = :inet.gethostname()
    to_string(hostname_charlist)
  end
end
