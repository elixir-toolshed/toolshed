defmodule Toolshed.NervesRuntime.FwValidate do
  @doc """
  Validate a firmware image

  All official Nerves Systems automatically validate newly installed firmware.
  For some systems, it's possible to disable this so that new firmware gets
  one chance to boot. If it's not "validated" before a reboot, then the device
  reverts to the old firmware.
  """
  @spec fw_validate() :: :ok | {:error, String.t()}
  def fw_validate() do
    Nerves.Runtime.validate_firmware()
  catch
    :error, :undef ->
      # Fall back to the old Nerves way
      case System.cmd("fw_setenv", ["nerves_fw_validated", "1"]) do
        {_, 0} -> :ok
        {output, _} -> {:error, output}
      end
  end
end
