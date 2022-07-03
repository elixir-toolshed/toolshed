defmodule Toolshed.Ping do
  @moduledoc false

  def repeat_ping(address, options) do
    Toolshed.tping(address, options)
    Process.sleep(1000)
    repeat_ping(address, options)
  end
end
