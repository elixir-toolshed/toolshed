defmodule Toolshed do
  @moduledoc """
  Making the IEx console friendlier one command at a time

  To use the helpers, run:

      iex> use Toolshed

  Add this to your `.iex.exs` to load automatically.

  The following is a list of helpers:

    * `cat/1`          - print out a file
    * `cmd/1`          - run a system command and print the output
    * `date/0`         - print out the current date and time
    * `dmesg/0`        - print kernel messages (Nerves-only)
    * `exit/0`         - exit out of an IEx session
    * `fw_validate/0`  - marks the current image as valid (check Nerves system if supported)
    * `grep/2`         - print out lines that match a regular expression
    * `hex/1`          - print a number as hex
    * `history/0`      - print out the IEx shell history
    * `httpget/2`      - print or download the results of a HTTP GET request
    * `hostname/0`     - print our hostname
    * `ifconfig/0`     - print info on network interfaces
    * `load_term!/1`   - load a term that was saved by `save_term/2`
    * `log_attach/1`   - send log messages to the current group leader
    * `log_detach/0`   - stop sending log messages to the current group leader
    * `lsof/0`         - print out open file handles by OS process
    * `lsmod/0`        - print out what kernel modules have been loaded (Nerves-only)
    * `lsusb/0`        - print info on USB devices
    * `multicast_addresses/0` - print out all multicast addresses
    * `nslookup/1`     - query DNS to find an IP address
    * `ping/2`         - ping a remote host (but use TCP instead of ICMP)
    * `qr_encode/1`    - create a QR code (requires networking)
    * `reboot/0`       - reboots gracefully (Nerves-only)
    * `reboot!/0`      - reboots immediately  (Nerves-only)
    * `save_value/3`   - save a value to a file as Elixir terms (uses inspect)
    * `save_term!/2`   - save a term as a binary
    * `top/2`          - list out the top processes
    * `tping/2`        - check if a host can be reached (like ping, but uses TCP)
    * `tree/1`         - pretty print a directory tree
    * `uptime/0`       - print out the current Erlang VM uptime
    * `uname/0`        - print information about the running system (Nerves-only)
    * `weather/0`      - get the local weather (requires networking)

  """

  defmacro __using__(_) do
    quote do
      import Toolshed

      # If module docs have been stripped, then don't tell the user that they can
      # see them.
      help_text =
        case Code.fetch_docs(Toolshed) do
          {:error, _anything} -> ""
          _ -> " Run h(Toolshed) for more info."
        end

      Toolshed.Autocomplete.set_expand_fun()

      IO.puts([
        IO.ANSI.color(:rand.uniform(231) + 1),
        "Toolshed",
        IO.ANSI.reset(),
        " imported.",
        help_text
      ])
    end
  end

  @doc """
  Run a command and return the exit code. This function is intended to be run
  interactively.
  """
  @spec cmd(String.t() | charlist()) :: integer()
  def cmd(str) when is_binary(str) do
    {_collectable, exit_code} =
      System.cmd("sh", ["-c", str], stderr_to_stdout: true, into: IO.binstream(:stdio, :line))

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

  defdelegate cat(path), to: Toolshed.Cat
  defdelegate date(), to: Toolshed.Date
  defdelegate exit(), to: Toolshed.Misc
  defdelegate grep(regex, path), to: Toolshed.Grep
  defdelegate history(), to: Toolshed.History
  defdelegate hostname(), to: Toolshed.Net
  defdelegate httpget(url, options), to: Toolshed.HTTP
  defdelegate ifconfig(), to: Toolshed.Net
  defdelegate load_term!(path), to: Toolshed.Misc
  defdelegate log_attach(options), to: Toolshed.Log
  defdelegate log_detach(), to: Toolshed.Log
  defdelegate lsof(), to: Toolshed.Lsof
  defdelegate lsusb(), to: Toolshed.HW
  defdelegate multicast_addresses(), to: Toolshed.Multicast
  defdelegate nslookup(name), to: Toolshed.Net
  defdelegate ping(address, options), to: Toolshed.TCPPing
  defdelegate qr_encode(message), to: Toolshed.HTTP
  defdelegate save_term!(term, path), to: Toolshed.Misc
  defdelegate save_value(value, path, inspect_opts), to: Toolshed.Misc
  defdelegate top(), to: Toolshed.Top
  defdelegate tping(address, options), to: Toolshed.TCPPing
  defdelegate tree(), to: Toolshed.Tree
  defdelegate uptime(), to: Toolshed.Uptime
  defdelegate weather(), to: Toolshed.Weather

  # Nerves-specific functions
  if Code.ensure_loaded?(Nerves.Runtime) do
    defdelegate dmesg(), to: Toolshed.Nerves
    defdelegate fw_validate(), to: Toolshed.Nerves
    defdelegate lsmod(), to: Toolshed.Nerves
    @spec reboot!() :: no_return()
    defdelegate reboot!(), to: Toolshed.Nerves
    defdelegate reboot(), to: Toolshed.Nerves
    defdelegate uname(), to: Toolshed.Nerves
  end
end
