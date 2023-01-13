defmodule Toolshed.NervesRuntime.Dmesg do
  @doc """
  Print out kernel log messages
  """
  @spec dmesg() :: :"do not show this result in output"
  def dmesg() do
    Toolshed.cmd("dmesg")
    IEx.dont_display_result()
  end
end
