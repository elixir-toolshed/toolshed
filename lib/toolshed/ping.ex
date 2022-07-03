defmodule Toolshed.Ping do
  @moduledoc false

  @spec repeat_ping(binary, keyword) :: no_return
  def repeat_ping(address, options) do
    Toolshed.tping(address, options)
    Process.sleep(1000)
    repeat_ping(address, options)
  end
end
