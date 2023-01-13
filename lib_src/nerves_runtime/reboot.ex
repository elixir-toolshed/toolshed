defmodule Toolshed.NervesRuntime.Reboot do
  @doc """
  Shortcut to reboot a board. This is a graceful reboot, so it takes some time
  before the real reboot.
  """
  @spec reboot() :: no_return()
  defdelegate reboot(), to: Nerves.Runtime

  @doc """
  Reboot immediately without a graceful shutdown. This is for the impatient.
  """
  @spec reboot!() :: no_return()
  def reboot!() do
    :erlang.halt()
  end
end
