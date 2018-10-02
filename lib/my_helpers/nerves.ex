target = System.get_env("MIX_TARGET")

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
    Remote immediately without a graceful shutdown. This is for the impatient.
    """
    @spec reboot!() :: no_return()
    def reboot!() do
      :erlang.halt()
    end
  end
else
  defmodule MyHelpers.Nerves do
    defmacro __using__(_) do
      # Skip if not running on Nerves
    end
  end
end
