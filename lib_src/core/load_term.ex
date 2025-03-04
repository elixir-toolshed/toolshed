# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.Core.LoadTerm do
  @doc """
  Load an Erlang term from the filesystem.

  ## Examples

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
