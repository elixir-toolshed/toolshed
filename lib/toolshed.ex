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

  alias Toolshed.Utils

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
  Reads and prints out the contents of a file
  """
  @spec cat(Path.t()) :: :"do not show this result in output"
  def cat(path) do
    path
    |> File.read!()
    |> IO.write()

    IEx.dont_display_result()
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
  Return the date and time in UTC
  """
  @spec date() :: String.t()
  def date() do
    Toolshed.Date.date_in_unix_format(DateTime.utc_now())
  end

  @doc """
  Run a regular expression on a file and print the matching lines.

      iex> grep ~r/video/, "/etc/mime.types"

  If colored is enabled for the shell, the matches will be highlighted red.
  """
  @spec grep(Regex.t(), Path.t()) :: :"do not show this result in output"
  def grep(regex, path) do
    File.stream!(path)
    |> Stream.filter(&Regex.match?(regex, &1))
    |> Stream.map(fn line ->
      Regex.replace(regex, line, &IO.ANSI.format([:red, &1]))
    end)
    |> Stream.each(&IO.write/1)
    |> Stream.run()

    IEx.dont_display_result()
  end

  @doc """
  Inspect a value with all integers printed out in hex. This is useful for
  one-off hex conversions. If you're doing a lot of work that requires
  hexadecimal output, you should consider running:

  `IEx.configure(inspect: [base: :hex])`

  The drawback of doing the above is that strings print out as hex binaries.
  """
  @spec hex(integer()) :: String.t()
  def hex(value), do: inspect(value, base: :hex)

  @doc """
  Print out the IEx shell history

  The default is to print the history from the current group leader, but
  any group leader can be passed in if desired.
  """
  @spec history(pid()) :: :"do not show this result in output"
  def history(gl \\ Process.group_leader()) do
    commands = Toolshed.History.last_commands(gl)
    format = Toolshed.History.format_spec(length(commands))

    commands
    |> Enum.with_index(1)
    |> Enum.map(fn {line, index} -> :io_lib.format(format, [index, line]) end)
    |> IO.puts()

    :"do not show this result in output"
  end

  @doc """
  Return the hostname

  ## Examples

      iex> hostname
      "nerves-1234"
  """
  @spec hostname() :: String.t()
  def hostname() do
    {:ok, hostname_charlist} = :inet.gethostname()
    to_string(hostname_charlist)
  end

  @doc """
  Perform a HTTP GET request for the specified URL

  By default, the results are printed or you can optionally choose to download
  it to a specific location on the file system.

  Options:

  * `:dest` - File path to write the response to. Defaults to printing to the terminal.
  * `:verbose` - Display request and response headers. Disabled by default.
  """
  @spec httpget(String.t(), dest: Path.t(), verbose: boolean()) ::
          :"do not show this result in output"
  def httpget(url, options \\ []) do
    Utils.check_app(:inets)

    url = Toolshed.HTTP.url_defaults(url)
    dest = Keyword.get(options, :dest, nil)
    verbose = Keyword.get(options, :verbose, false)

    stream =
      if dest != nil do
        to_charlist(dest)
      else
        :self
      end

    request_headers = [{'User-Agent', 'curl'}]

    if verbose do
      Toolshed.HTTP.display_headers(request_headers, ">")
    end

    Task.async(fn ->
      {:ok, _ref} =
        :httpc.request(
          :get,
          {to_charlist(url), request_headers},
          [],
          sync: false,
          stream: stream
        )

      Toolshed.HTTP.handle_stream(verbose)
    end)
    |> Task.await()

    IEx.dont_display_result()
  end

  @doc """
  Print out the network interfaces and their addresses.
  """
  @spec ifconfig() :: :"do not show this result in output"
  def ifconfig() do
    {:ok, if_list} = :inet.getifaddrs()
    Enum.each(if_list, &Toolshed.Ifconfig.print_if/1)
    IEx.dont_display_result()
  end

  @doc """
  Load an Erlang term from the filesystem.

  ## Examples

      iex> save_term!({:some_interesting_atom, ["some", "list"]}, "/root/some_atom.term")
      {:some_interesting_atom, ["some", "list"]}
      iex> load_term!("/root/some_atom.term")
      {:some_interesting_atom, ["some", "list"]}
  """
  @spec load_term!(Path.t()) :: term()
  def load_term!(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end

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
  @spec log_attach(keyword()) :: {:error, any} | {:ok, :undefined | pid}
  def log_attach(options \\ []) do
    case Process.get(__MODULE__) do
      nil ->
        all_options = Keyword.put(options, :device, Process.group_leader())
        backend = {Logger.Backends.Console, all_options}

        {:ok, pid} = GenServer.start(Toolshed.Log.Watcher, {Process.group_leader(), backend})

        Process.put(__MODULE__, {pid, backend})

        Logger.add_backend({Logger.Backends.Console, all_options})

      _other ->
        {:error, :detach_first}
    end
  end

  @doc """
  Detach the current session from the Elixir logger
  """
  @spec log_detach :: :ok | {:error, :not_attached | :not_found}
  def log_detach() do
    case Process.get(__MODULE__) do
      nil ->
        {:error, :not_attached}

      {pid, backend} ->
        Process.delete(__MODULE__)
        GenServer.stop(pid)
        Logger.remove_backend(backend)
    end
  end

  @doc """
  List out open files by process

  This is an simple version of lsof that works on Linux and
  Nerves. While running the normal version of lsof provides
  more information, this can be convenient when lsof isn't
  easily available or can't be run due to `:emfile` errors
  from starting port processes due to too many files being open..
  """
  @spec lsof() :: :ok
  def lsof() do
    Toolshed.Lsof.path_ls("/proc")
    |> Enum.filter(&File.dir?/1)
    |> Enum.each(&Toolshed.Lsof.lsof_process/1)
  end

  @doc """
  Print out information on all of the connected USB devices.
  """
  @spec lsusb() :: :"do not show this result in output"
  def lsusb() do
    Enum.each(Path.wildcard("/sys/bus/usb/devices/*/uevent"), &Toolshed.Lsusb.print_usb/1)
    IEx.dont_display_result()
  end

  @doc """
  List all active multicast addresses

  This lists out multicast addresses by network interface
  similar to `ip maddr show`. It currently only works on
  Linux.
  """
  @spec multicast_addresses() :: :ok
  def multicast_addresses() do
    dev_mcast = Utils.read_or_empty("/proc/net/dev_mcast")
    igmp = Utils.read_or_empty("/proc/net/igmp")
    igmp6 = Utils.read_or_empty("/proc/net/igmp6")

    Toolshed.Multicast.process_proc(dev_mcast, igmp, igmp6)
    |> IO.puts()
  end

  @doc """
  Lookup the specified hostname in the DNS and print out the addresses.

  ## Examples

      iex> nslookup "google.com"
      Name:     google.com
      Address:  172.217.7.238
      Address:  2607:f8b0:4004:804::200e
  """
  @spec nslookup(String.t()) :: :"do not show this result in output"
  def nslookup(name) do
    IO.puts("Name:     #{name}")
    name_charlist = to_charlist(name)

    case :inet.gethostbyname(name_charlist, :inet) do
      {:ok, v4} -> Toolshed.Nslookup.print_addresses(v4)
      {:error, :nxdomain} -> IO.puts("IPv4 lookup failed")
    end

    case :inet.gethostbyname(name_charlist, :inet6) do
      {:ok, v6} -> Toolshed.Nslookup.print_addresses(v6)
      {:error, :nxdomain} -> IO.puts("IPv6 lookup failed")
    end

    IEx.dont_display_result()
  end

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
  @spec ping(String.t(), keyword()) :: :"do not show this result in output"
  def ping(address, options \\ []) do
    IO.puts("Press enter to stop")

    pid = spawn(fn -> Toolshed.Ping.repeat_ping(address, options) end)
    _ = IO.gets("")
    Process.exit(pid, :kill)

    IEx.dont_display_result()
  end

  @doc """
  Generate an ASCII art QR code

  See https://github.com/chubin/qrenco.de for more information.
  """
  @spec qr_encode(String.t()) :: :"do not show this result in output"
  def qr_encode(message) do
    Utils.check_app(:inets)

    encoded = message |> URI.encode() |> to_charlist()
    form_data = [?x, ?= | encoded]

    {:ok, {_status, _headers, body}} =
      :httpc.request(
        :post,
        {'http://qrenco.de/', [{'User-Agent', 'curl'}], 'application/x-www-form-urlencoded',
         form_data},
        [],
        []
      )

    body |> :binary.list_to_bin() |> IO.puts()
    IEx.dont_display_result()
  end

  @doc """
  Save an Erlang term to the filesystem for easy loading later

  This function returns the `value` passed in to allow easy piping.

  ## Examples

      iex> :sys.get_state(MyServer) |> save_term!("/root/my_server.term")
      # Reboot board
      iex> :sys.replace_state(&load_term!("/root/my_server.term"))
  """
  @spec save_term!(term, Path.t()) :: term()
  def save_term!(value, path) do
    term = :erlang.term_to_binary(value)
    :ok = File.write!(path, term)
    value
  end

  @doc """
  Save a value to a file as Elixir terms

  ## Examples

      # Save the contents of SystemRegistry to a file
      iex> SystemRegistry.match(:_) |> save_value("/root/sr.txt")
      :ok
  """
  @spec save_value(any(), Path.t(), keyword()) :: :ok | {:error, File.posix()}
  def save_value(value, path, inspect_opts \\ []) do
    opts =
      Keyword.merge([pretty: true, limit: :infinity, printable_limit: :infinity], inspect_opts)

    contents = inspect(value, opts)
    File.write(path, contents)
  end

  @doc """
  Interactively show the top Elixir processes

  This is intended to be called from the IEx prompt and will periodically
  update the console with the top processes. Press enter to exit.

  Options:

  * `:order` - the sort order for the results (`:reductions`, `:delta_reductions`,
    `:mailbox`, `:delta_mailbox`, `:total_heap_size`, `:delta_total_heap_size`, `:heap_size`,
    `:delta_heap_size`, `:stack_size`, `:delta_stack_size`)
  """
  @spec top(keyword()) :: :ok
  def top(opts \\ []) do
    alias Toolshed.Top

    options = %{
      order: Keyword.get(opts, :order, :delta_reductions),
      rows: Top.rows(),
      columns: Top.columns()
    }

    IO.puts("Press enter to stop\n")

    {:ok, pid} = Top.Server.start_link(options)
    _ = IO.gets("")
    Top.Server.stop(pid)
  end

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
  @spec tping(String.t(), keyword()) :: :"do not show this result in output"
  def tping(address, options \\ []) do
    case Toolshed.Tping.resolve_addr(address) do
      {:ok, ip} ->
        port = Keyword.get(options, :port, 80)
        Toolshed.Tping.ping_ip(address, ip, port, Toolshed.Tping.connect_options(options))

      {:error, message} ->
        IO.puts(message)
    end

    IEx.dont_display_result()
  end

  @doc """
  Print out directories and files in tree form.
  """
  @spec tree(Path.t()) :: :"do not show this result in output"
  def tree(path \\ ".") do
    IO.puts(path)

    case Toolshed.Tree.file_info(path, path) do
      {:directory, _} ->
        Toolshed.Tree.do_tree("", path, Toolshed.Tree.files(path))

      _ ->
        :ok
    end

    IEx.dont_display_result()
  end

  @doc """
  Print out the current uptime.
  """
  @spec uptime() :: :"do not show this result in output"
  def uptime() do
    :c.uptime()
    IEx.dont_display_result()
  end

  @doc """
  Display the local weather

  See http://wttr.in/:help for more information.
  """
  @spec weather() :: :"do not show this result in output"
  def weather() do
    Utils.check_app(:inets)
    Utils.check_app(:ssl)

    Toolshed.Weather.get_weather() |> IO.puts()
    IEx.dont_display_result()
  end

  # Nerves-specific functions
  if Code.ensure_loaded?(Nerves.Runtime) do
    @doc """
    Print out kernel log messages
    """
    @spec dmesg() :: :"do not show this result in output"
    def dmesg() do
      cmd("dmesg")
      IEx.dont_display_result()
    end

    @doc """
    Exit the current IEx session
    """
    @spec exit() :: true
    def exit(), do: Process.exit(Process.group_leader(), :kill)

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
    Print out the loaded kernel modules

    Aside from printing out whether the kernel has been tainted, the
    Linux utility of the same name just dump the contents of "/proc/modules"
    like this one.

    Some kernel modules may be built-in to the kernel image. To see
    those, run `cat "/lib/modules/x.y.z/modules.builtin"` where `x.y.z` is
    the kernel's version number.
    """
    @spec lsmod() :: :"do not show this result in output"
    def lsmod(), do: cat("/proc/modules")

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
    def reboot!(), do: :erlang.halt()

    @doc """
    Print out information about the running software

    This is similar to the Linux `uname` to help people remember what to type.
    """
    @spec uname() :: :"do not show this result in output"
    def uname() do
      alias Nerves.Runtime.KV

      sysname = "Nerves"
      nodename = Toolshed.hostname()
      release = KV.get_active("nerves_fw_product")
      version = "#{KV.get_active("nerves_fw_version")} (#{KV.get_active("nerves_fw_uuid")})"
      arch = KV.get_active("nerves_fw_architecture")

      IO.puts("#{sysname} #{nodename} #{release} #{version} #{arch}")
      IEx.dont_display_result()
    end
  end
end
