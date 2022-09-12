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
    * `grep/2`         - print out lines that match a regular expression
    * `hex/1`          - print a number as hex
    * `history/0`      - print out the IEx shell history
    * `httpget/2`      - print or download the results of a HTTP GET request
    * `hostname/0`     - print our hostname
    * `ifconfig/0`     - print info on network interfaces
    * `load_term!/1`   - load a term that was saved by `save_term!/2`
    * `log_attach/1`   - send log messages to the current group leader
    * `log_detach/0`   - stop sending log messages to the current group leader
    * `lsof/0`         - print out open file handles by OS process
    * `lsusb/0`        - print info on USB devices
    * `multicast_addresses/0` - print out all multicast addresses
    * `nslookup/1`     - query DNS to find an IP address
    * `ping/2`         - ping a remote host (but use TCP instead of ICMP)
    * `qr_encode/1`    - create a QR code (requires networking)
    * `save_value/3`   - save a value to a file as Elixir terms (uses inspect)
    * `save_term!/2`   - save a term as a binary
    * `top/2`          - list out the top processes
    * `tping/2`        - check if a host can be reached (like ping, but uses TCP)
    * `tree/1`         - pretty print a directory tree
    * `uptime/0`       - print out the current Erlang VM uptime
    * `weather/0`      - get the local weather (requires networking)

  """

  defmacro __using__(_) do
    quote do
      import IEx.Helpers, except: [h: 1]
      import Toolshed
      require Toolshed

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

      if unquote(Code.ensure_loaded?(Nerves.Runtime) and not Code.ensure_loaded?(Toolshed.Nerves)) do
        IO.warn("""
        Nerves-specific helpers have been removed from :toolshed.
        Add :toolshed_nerves to your Nerves project's dependencies.
        """)
      end

      if unquote(Code.ensure_loaded?(Toolshed.Nerves)) do
        IO.warn("""
        Using Toolshed in a Nerves project is deprecated, instead of:

            use Toolshed

        do:

            use Toolshed.Nerves
        """)
      end
    end
  end

  @doc false
  defmacro h(term) do
    quote do
      target =
        case unquote(IEx.Introspection.decompose(term, __CALLER__)) do
          {Toolshed, :h} ->
            {Toolshed, :h}

          # function doc
          {m, f} ->
            case to_string(m) do
              # Toolshed or Toolshed* modules
              "Elixir.Toolshed" <> _ ->
                f_module = f |> Atom.to_string() |> Macro.camelize()
                {Module.concat(m, f_module), f}

              _other ->
                {m, f}
            end

          # module doc
          other ->
            other
        end

      IEx.Introspection.h(target)
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
  defdelegate grep(regex, path), to: Toolshed.Grep
  defdelegate history(gl \\ Process.group_leader()), to: Toolshed.History
  defdelegate hostname(), to: Toolshed.Hostname
  defdelegate httpget(url, options \\ []), to: Toolshed.Httpget
  defdelegate ifconfig(), to: Toolshed.Ifconfig
  defdelegate load_term!(path), to: :"Elixir.Toolshed.LoadTerm!"
  defdelegate log_attach(options \\ []), to: Toolshed.LogAttach
  defdelegate log_detach(), to: Toolshed.LogDetach
  defdelegate lsof(), to: Toolshed.Lsof
  defdelegate lsusb(), to: Toolshed.Lsusb
  defdelegate multicast_addresses(), to: Toolshed.MulticastAddresses
  defdelegate nslookup(name), to: Toolshed.Nslookup
  defdelegate ping(address, options \\ []), to: Toolshed.Ping
  defdelegate qr_encode(message), to: Toolshed.QrEncode
  defdelegate save_term!(term, path), to: :"Elixir.Toolshed.SaveTerm!"
  defdelegate save_value(value, path, inspect_opts \\ []), to: Toolshed.SaveValue
  defdelegate top(opts \\ []), to: Toolshed.Top
  defdelegate tping(address, options \\ []), to: Toolshed.Tping
  defdelegate tree(path \\ "."), to: Toolshed.Tree
  defdelegate uptime(), to: Toolshed.Uptime
  defdelegate weather(), to: Toolshed.Weather
end
