# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.NervesRuntime.Exit do
  @doc """
  Exit the current IEx session
  """
  @spec exit() :: true
  def exit() do
    Process.exit(Process.group_leader(), :kill)
  end
end
