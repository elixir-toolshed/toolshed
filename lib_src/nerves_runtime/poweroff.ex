defmodule Toolshed.NervesRuntime.Poweroff do
  @doc """
  Helper for gracefully powering off

  Not all Nerves devices support powering themselves off. These devices reboot
  instead.
  """
  @spec poweroff() :: no_return()
  defdelegate poweroff(), to: Nerves.Runtime
end
