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

  @doc """
  Reads and prints out the contents of a file
  """
  defdelegate cat(path), to: Toolshed.Cat

  @doc """
  Return the date and time in UTC
  """
  defdelegate date(), to: Toolshed.Date

  @doc """
  Run a regular expression on a file and print the matching lines.

      iex> grep ~r/video/, "/etc/mime.types"

  If colored is enabled for the shell, the matches will be highlighted red.
  """
  defdelegate grep(regex, path), to: Toolshed.Grep

  @doc """
  Print out the IEx shell history

  The default is to print the history from the current group leader, but
  any group leader can be passed in if desired.
  """
  defdelegate history(), to: Toolshed.History

  @doc """
  Return the hostname

  ## Examples

      iex> hostname
      "nerves-1234"
  """
  defdelegate hostname(), to: Toolshed.Hostname

  @doc """
  Perform a HTTP GET request for the specified URL

  By default, the results are printed or you can optionally choose to download
  it to a specific location on the file system.

  Options:

  * `:dest` - File path to write the response to. Defaults to printing to the terminal.
  * `:verbose` - Display request and response headers. Disabled by default.
  """
  defdelegate httpget(url, options \\ []), to: Toolshed.HTTP

  @doc """
  Print out the network interfaces and their addresses.
  """
  defdelegate ifconfig(), to: Toolshed.Ifconfig

  @doc """
  Load an Erlang term from the filesystem.

  ## Examples

      iex> save_term!({:some_interesting_atom, ["some", "list"]}, "/root/some_atom.term")
      {:some_interesting_atom, ["some", "list"]}
      iex> load_term!("/root/some_atom.term")
      {:some_interesting_atom, ["some", "list"]}
  """
  defdelegate load_term!(path), to: Toolshed.Misc

  @doc """
  Attach the current session to the Elixir logger

  This forwards incoming log messages to the terminal. Call `detach/0` to stop
  the messages.

  Behind the scenes, this uses Elixir's built-in console logger and can be
  configured similarly. See the [Logger console backend
  documentation](https://hexdocs.pm/logger/Logger.html#module-console-backend)
  for details. The following are useful options:

  * `:level` - the minimum log level to report. E.g., specify `level: :warning`
    to only see warnings and errors.
  * `:metadata` - a list of metadata keys to show or `:all`

  Unspecified options use either the console backend's default or those found
  in the application environment for the `:console` Logger backend.
  """
  defdelegate log_attach(options \\ []), to: Toolshed.Log

  @doc """
  Detach the current session from the Elixir logger
  """
  defdelegate log_detach(), to: Toolshed.Log

  @doc """
  List out open files by process

  This is an simple version of lsof that works on Linux and
  Nerves. While running the normal version of lsof provides
  more information, this can be convenient when lsof isn't
  easily available or can't be run due to `:emfile` errors
  from starting port processes due to too many files being open..
  """
  defdelegate lsof(), to: Toolshed.Lsof

  @doc """
  Print out information on all of the connected USB devices.
  """
  defdelegate lsusb(), to: Toolshed.Lsusb

  @doc """
  List all active multicast addresses

  This lists out multicast addresses by network interface
  similar to `ip maddr show`. It currently only works on
  Linux.
  """
  defdelegate multicast_addresses(), to: Toolshed.Multicast

  @doc """
  Lookup the specified hostname in the DNS and print out the addresses.

  ## Examples

      iex> nslookup "google.com"
      Name:     google.com
      Address:  172.217.7.238
      Address:  2607:f8b0:4004:804::200e
  """
  defdelegate nslookup(name), to: Toolshed.Nslookup

  @doc """
  Ping an IP address using TCP

  This tries to connect to the remote host using TCP instead of sending an ICMP
  echo request like normal ping. This made it possible to write in pure Elixir.

  NOTE: Specifying an `:ifname` only sets the source IP address for the TCP
  connection. This is only a hint to use the specified interface and not a
  guarantee. For example, if you have two interfaces on the same LAN, the OS
  routing tables may send traffic out one interface in preference to the one
  that you want. On Linux, you can enable policy-based routing and add source
  routes to guarantee that packets go out the desired interface.

  Options:

  * `:ifname` - Specify a network interface to use. (e.g., "eth0")
  * `:port` - Which TCP port to try (defaults to 80)

  ## Examples

      iex> ping "nerves-project.org"
      Press enter to stop
      Response from nerves-project.org (185.199.108.153:80): time=4.155ms
      Response from nerves-project.org (185.199.108.153:80): time=10.385ms
      Response from nerves-project.org (185.199.108.153:80): time=12.458ms

      iex> ping "google.com", ifname: "wlp5s0"
      Press enter to stop
      Response from google.com (172.217.7.206:80): time=88.602ms
  """
  defdelegate ping(address, options \\ []), to: Toolshed.Ping

  @doc """
  Generate an ASCII art QR code

  See https://github.com/chubin/qrenco.de for more information.
  """
  defdelegate qr_encode(message), to: Toolshed.HTTP

  @doc """
  Save an Erlang term to the filesystem for easy loading later

  This function returns the `value` passed in to allow easy piping.

  ## Examples

      iex> :sys.get_state(MyServer) |> save_term!("/root/my_server.term")
      # Reboot board
      iex> :sys.replace_state(&load_term!("/root/my_server.term"))
  """
  defdelegate save_term!(term, path), to: Toolshed.Misc

  @doc """
  Save a value to a file as Elixir terms

  ## Examples

      # Save the contents of SystemRegistry to a file
      iex> SystemRegistry.match(:_) |> save_value("/root/sr.txt")
      :ok
  """
  defdelegate save_value(value, path, inspect_opts \\ []), to: Toolshed.Misc

  @doc """
  Interactively show the top Elixir processes

  This is intended to be called from the IEx prompt and will periodically
  update the console with the top processes. Press enter to exit.

  Options:

  * `:order` - the sort order for the results (`:reductions`, `:delta_reductions`,
    `:mailbox`, `:delta_mailbox`, `:total_heap_size`, `:delta_total_heap_size`, `:heap_size`,
    `:delta_heap_size`, `:stack_size`, `:delta_stack_size`)
  """
  defdelegate top(), to: Toolshed.Top

  @doc """
  Check if a computer is up using TCP.

  Options:

  * `:ifname` - Specify a network interface to use. (e.g., "eth0")
  * `:port` - Which TCP port to try (defaults to 80)

  ## Examples

      iex> tping "nerves-project.org"
      Response from nerves-project.org (185.199.108.153:80): time=4.155ms

      iex> tping "192.168.1.1"
      Response from 192.168.1.1 (192.168.1.1:80): time=1.227ms
  """
  defdelegate tping(address, options \\ []), to: Toolshed.Tping

  @doc """
  Print out directories and files in tree form.
  """
  defdelegate tree(), to: Toolshed.Tree

  @doc """
  Print out the current uptime.
  """
  defdelegate uptime(), to: Toolshed.Uptime

  @doc """
  Display the local weather

  See http://wttr.in/:help for more information.
  """
  defdelegate weather(), to: Toolshed.Weather

  # Nerves-specific functions
  if Code.ensure_loaded?(Nerves.Runtime) do
    @doc """
    Print out kernel log messages
    """
    defdelegate dmesg(), to: Toolshed.Nerves

    @doc """
    Exit the current IEx session
    """
    defdelegate exit(), to: Toolshed.Nerves

    @doc """
    Validate a firmware image

    All official Nerves Systems automatically validate newly installed firmware.
    For some systems, it's possible to disable this so that new firmware gets
    one chance to boot. If it's not "validated" before a reboot, then the device
    reverts to the old firmware.
    """
    defdelegate fw_validate(), to: Toolshed.Nerves

    @doc """
    Print out the loaded kernel modules

    Aside from printing out whether the kernel has been tainted, the
    Linux utility of the same name just dump the contents of "/proc/modules"
    like this one.

    Some kernel modules may be built-in to the kernel image. To see
    those, run `cat "/lib/modules/x.y.z/modules.builtin"` where `x.y.z` is
    the kernel's version number.
    """
    defdelegate lsmod(), to: Toolshed.Nerves

    @doc """
    Reboot immediately without a graceful shutdown. This is for the impatient.
    """
    @spec reboot!() :: no_return()
    defdelegate reboot!(), to: Toolshed.Nerves

    @doc """
    Shortcut to reboot a board. This is a graceful reboot, so it takes some time
    before the real reboot.
    """
    defdelegate reboot(), to: Toolshed.Nerves

    @doc """
    Print out information about the running software

    This is similar to the Linux `uname` to help people remember what to type.
    """
    defdelegate uname(), to: Toolshed.Nerves
  end
end
