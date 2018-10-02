defmodule Toolshed do
  @moduledoc """
  Making the IEx console friendlier one command at a time

  To use the helpers, run:

      iex> use Toolshed

  Add this to your `.iex.exs` to load automatically.

  The follow is a list of helpers:

    * `cmd/1`          - run a system command and print the output
    * `hex/1`          - print a number as hex
    * `top/2`          - list out the top processes
    * `cat/1`          - print out a file
    * `grep/2`         - print out lines that match a regular expression
    * `tree/1`         - pretty print a directory tree
    * `hostname/0`     - print our hostname
    * `nslookup/1`     - query DNS to find an IP address
    * `tping/1`        - check if a host can be reached (like ping, but uses TCP)
    * `ifconfig/0`     - print info on network interfaces
    * `dmesg/0`        - print kernel messages
    * `reboot/0`       - reboots gracefully
    * `reboot!/0`      - reboots immediately
    * `fw_validate/0`  - marks the current image as valid (check Nerves system if supported)
    * `save_value/2`   - save a value to a file as Elixir terms (uses inspect)
    * `save_term!/2`   - save a term as a binary
    * `load_term!/2`   - load a term that was saved by `save_term/2`
    * `lsusb/0`        - print info on USB devices
  """

  defmacro __using__(_) do
    quote do
      import Toolshed
      use Toolshed.Top
      use Toolshed.Nerves
      use Toolshed.Unix
      use Toolshed.Net
      use Toolshed.Misc
      use Toolshed.HW
      IO.puts("Toolshed imported. Run h(Toolshed) for more info")
    end
  end

  @doc """
  Run a command and return the exit code. This function is intended to be run
  interactively.
  """
  @spec cmd(String.t() | charlist()) :: integer()
  def cmd(str) when is_binary(str) do
    {_collectable, exit_code} = System.cmd("sh", ["-c", str], into: IO.stream(:stdio, :line))
    exit_code
  end

  def cmd(str) when is_list(str) do
    str |> to_string |> cmd
  end

  @doc """
  Inspect a value with all integers printed out in hex. This is useful for
  one-off hex conversions. If you're doing a lot of work that requires
  hexadecimal output, you should consider running:

  `IEx.configure(inspect: [base: :hex])`

  The drawback of doing the above is that strings print out as hex binaries.
  """
  @spec hex(integer()) :: String.t()
  def hex(value) do
    inspect(value, base: :hex)
  end
end
