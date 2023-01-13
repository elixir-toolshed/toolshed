defmodule Toolshed.NervesRuntime.Uname do
  alias Nerves.Runtime.KV

  @doc """
  Print out information about the running software

  This is similar to the Linux `uname` to help people remember what to type.
  """
  @spec uname() :: :"do not show this result in output"
  def uname() do
    sysname = "Nerves"
    nodename = Toolshed.hostname()
    release = KV.get_active("nerves_fw_product")

    version = "#{KV.get_active("nerves_fw_version")} (#{KV.get_active("nerves_fw_uuid")})"

    arch = KV.get_active("nerves_fw_architecture")

    IO.puts("#{sysname} #{nodename} #{release} #{version} #{arch}")
    IEx.dont_display_result()
  end
end
