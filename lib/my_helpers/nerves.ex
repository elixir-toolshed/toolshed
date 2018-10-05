target = Mix.Project.config()[:target]

if target != nil and target != "host" do
  defmodule MyHelpers.Nerves do
    @moduledoc """
    Helpers that are useful on Nerves devices

    Helpers include:

     * `dmesg/0`   - print kernel messages
     * `reboot/0`  - reboots gracefully
     * `reboot!/0` - reboots immediately
    """

    defmacro __using__(_) do
      quote do
        import MyHelpers.Nerves
      end
    end

    @doc """
    Print out kernel log messages
    """
    @spec dmesg() :: :"do not show this result in output"
    def dmesg() do
      MyHelpers.cmd("dmesg")
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
      case System.cmd("fw_setenv", ["nerves_fw_validated", "1"]) do
        {_, 0} -> :ok
        {output, _} -> {:error, output}
      end
    end
  end
else
  defmodule MyHelpers.Nerves do
    defmacro __using__(_) do
      # Skip if not running on Nerves
    end
  end
end
