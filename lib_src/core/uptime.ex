defmodule Toolshed.Core.Uptime do
  @doc """
  Print out the current uptime.
  """
  @spec uptime() :: :"do not show this result in output"
  def uptime() do
    :c.uptime()
    IEx.dont_display_result()
  end
end
