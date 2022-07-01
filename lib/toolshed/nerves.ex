if Code.ensure_loaded?(Nerves.Runtime) do
  defmodule Toolshed.Nerves do
    @moduledoc """
    Helpers that are useful on Nerves devices

    Helpers include:

    * `dmesg/0`        - print kernel messages
    * `fw_validate/0`  - marks the current image as valid (check Nerves system if supported)
    * `lsmod/0`        - print out what kernel modules have been loaded
    * `reboot/0`       - reboots gracefully
    * `reboot!/0`      - reboots immediately
    * `uname/0`        - print information about the running system
    """

    alias Nerves.Runtime.KV

    @doc """
    Print out kernel log messages
    """
    @spec dmesg() :: :"do not show this result in output"
    def dmesg() do
      Toolshed.cmd("dmesg")
      IEx.dont_display_result()
    end

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

    @doc """
    Print out information about the running software

    This is similar to the Linux `uname` to help people remember what to type.
    """
    @spec uname() :: :"do not show this result in output"
    def uname() do
      sysname = "Nerves"
      nodename = Toolshed.Hostname.hostname()
      release = KV.get_active("nerves_fw_product")

      version = "#{KV.get_active("nerves_fw_version")} (#{KV.get_active("nerves_fw_uuid")})"

      arch = KV.get_active("nerves_fw_architecture")

      IO.puts("#{sysname} #{nodename} #{release} #{version} #{arch}")
      IEx.dont_display_result()
    end

    @doc """
    Print out the loaded kernel modules

    Aside from printing out whether the kernel has been tainted, the
    Linux utility of the same name just dump the contents of "/proc/modules"
    like this one.

    Some kernel modules may be built-in to the kernel image. To see
    those, run `cat "/lib/modules/x.y.z/modules.builtin"` where `x.y.z` is
    the kernel's version number.
    """
    @spec lsmod() :: :"do not show this result in output"
    def lsmod() do
      Toolshed.Unix.cat("/proc/modules")
    end
  end
end
