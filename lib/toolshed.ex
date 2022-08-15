# Get the doc of a function at compile time
get_function_doc = fn m, f, arity ->
  Code.ensure_compiled!(m)

  with {:docs_v1, _, _, _, _, _, functions} <- Code.fetch_docs(m),
       {_, _, _, %{"en" => doc}, _} <-
         Enum.find(functions, &Kernel.match?({{:function, ^f, ^arity}, _, _, _, _}, &1)) do
    doc
  else
    _ -> raise "could not find a doc for #{m}.#{f}/#{arity}"
  end
end

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

  @doc get_function_doc.(Toolshed.Cat, :cat, 1)
  defdelegate cat(path), to: Toolshed.Cat

  @doc get_function_doc.(Toolshed.Date, :date, 0)
  defdelegate date(), to: Toolshed.Date

  @doc get_function_doc.(Toolshed.Grep, :grep, 2)
  defdelegate grep(regex, path), to: Toolshed.Grep

  @doc get_function_doc.(Toolshed.History, :history, 1)
  defdelegate history(gl \\ Process.group_leader()), to: Toolshed.History

  @doc get_function_doc.(Toolshed.Hostname, :hostname, 0)
  defdelegate hostname(), to: Toolshed.Hostname

  @doc get_function_doc.(Toolshed.HTTP, :httpget, 2)
  defdelegate httpget(url, options \\ []), to: Toolshed.HTTP

  @doc get_function_doc.(Toolshed.Ifconfig, :ifconfig, 0)
  defdelegate ifconfig(), to: Toolshed.Ifconfig

  @doc get_function_doc.(Toolshed.Misc, :load_term!, 1)
  defdelegate load_term!(path), to: Toolshed.Misc

  @doc get_function_doc.(Toolshed.Log, :log_attach, 1)
  defdelegate log_attach(options \\ []), to: Toolshed.Log

  @doc get_function_doc.(Toolshed.Log, :log_detach, 0)
  defdelegate log_detach(), to: Toolshed.Log

  @doc get_function_doc.(Toolshed.Lsof, :lsof, 0)
  defdelegate lsof(), to: Toolshed.Lsof

  @doc get_function_doc.(Toolshed.Lsusb, :lsusb, 0)
  defdelegate lsusb(), to: Toolshed.Lsusb

  @doc get_function_doc.(Toolshed.Multicast, :multicast_addresses, 0)
  defdelegate multicast_addresses(), to: Toolshed.Multicast

  @doc get_function_doc.(Toolshed.Nslookup, :nslookup, 1)
  defdelegate nslookup(name), to: Toolshed.Nslookup

  @doc get_function_doc.(Toolshed.Ping, :ping, 2)
  defdelegate ping(address, options \\ []), to: Toolshed.Ping

  @doc get_function_doc.(Toolshed.HTTP, :qr_encode, 1)
  defdelegate qr_encode(message), to: Toolshed.HTTP

  @doc get_function_doc.(Toolshed.Misc, :save_term!, 2)
  defdelegate save_term!(term, path), to: Toolshed.Misc

  @doc get_function_doc.(Toolshed.Misc, :save_value, 3)
  defdelegate save_value(value, path, inspect_opts \\ []), to: Toolshed.Misc

  @doc get_function_doc.(Toolshed.Top, :top, 1)
  defdelegate top(opts \\ []), to: Toolshed.Top

  @doc get_function_doc.(Toolshed.Tping, :tping, 2)
  defdelegate tping(address, options \\ []), to: Toolshed.Tping

  @doc get_function_doc.(Toolshed.Tree, :tree, 1)
  defdelegate tree(opts \\ []), to: Toolshed.Tree

  @doc get_function_doc.(Toolshed.Uptime, :uptime, 0)
  defdelegate uptime(), to: Toolshed.Uptime

  @doc get_function_doc.(Toolshed.Weather, :weather, 0)
  defdelegate weather(), to: Toolshed.Weather

  # Nerves-specific functions
  if Code.ensure_loaded?(Nerves.Runtime) do
    @doc get_function_doc.(Toolshed.Nerves, :dmesg, 0)
    defdelegate dmesg(), to: Toolshed.Nerves

    @doc get_function_doc.(Toolshed.Nerves, :exit, 0)
    defdelegate exit(), to: Toolshed.Nerves

    @doc get_function_doc.(Toolshed.Nerves, :fw_validate, 0)
    defdelegate fw_validate(), to: Toolshed.Nerves

    @doc get_function_doc.(Toolshed.Nerves, :lsmod, 0)
    defdelegate lsmod(), to: Toolshed.Nerves

    @spec reboot!() :: no_return()
    @doc get_function_doc.(Toolshed.Nerves, :reboot!, 0)
    defdelegate reboot!(), to: Toolshed.Nerves

    @doc get_function_doc.(Toolshed.Nerves, :reboot, 0)
    defdelegate reboot(), to: Toolshed.Nerves

    @doc get_function_doc.(Toolshed.Nerves, :uname, 0)
    defdelegate uname(), to: Toolshed.Nerves
  end
end
