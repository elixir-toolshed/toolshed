defmodule Toolshed.Core.Tcping do
  @doc """
  Ping an IP address using TCP

  This tries to connect to the remote host using TCP instead of sending an ICMP
  echo request like normal ping. This sometimes works better than ping
  if the remote server or any machine in between drops ICMP messages.

  Options:

  * `:count` - number of pings to send (defaults to 3)
  * `:ifname` - Specify a network interface to use. (e.g., "eth0")
  * `:port` - Which TCP port to try (defaults to 80)

  ## Examples

      iex> tcping "nerves-project.org"
      Response from nerves-project.org (185.199.108.153:80): time=4.155ms
      Response from nerves-project.org (185.199.108.153:80): time=10.385ms
      Response from nerves-project.org (185.199.108.153:80): time=12.458ms

      iex> tcping "google.com", ifname: "wlp5s0"
      Response from google.com (172.217.7.206:80): time=88.602ms
  """
  @spec tcping(String.t(), keyword()) :: :"do not show this result in output"
  def tcping(address, options \\ []) do
    count = options[:count] || 3
    run_or_enter(fn -> repeat_tcping(address, options, 0, count) end)

    IEx.dont_display_result()
  end

  defp repeat_tcping(_address, _options, count, max_count)
       when count >= max_count,
       do: :ok

  defp repeat_tcping(address, options, count, max_count) do
    if count > 0, do: Process.sleep(1000)

    do_tcping(address, options)
    Process.sleep(1000)
    repeat_tcping(address, options, count + 1, max_count)
  end

  defp do_tcping(address, options) do
    case resolve_addr(address) do
      {:ok, ip} -> tcping_ip(address, ip, options)
      {:error, message} -> message
    end
    |> IO.puts()

    IEx.dont_display_result()
  end

  defp tcping_ip(address, ip, options) do
    port = Keyword.get(options, :port, 80)

    case try_connect(ip, port, options) do
      {:ok, micros} ->
        "Response from #{address} (#{pretty_ip_port(ip, port)}): time=#{micros / 1000}ms"

      {:error, reason} ->
        "#{address} (#{pretty_ip_port(ip, port)}): #{inspect(reason)}"
    end
  end

  defp pretty_ip_port({_, _, _, _} = ip, port), do: "#{:inet.ntoa(ip)}:#{port}"
  defp pretty_ip_port(ip, port), do: "[#{:inet.ntoa(ip)}]:#{port}"

  defp try_connect(address, port, options) do
    start = System.monotonic_time(:microsecond)

    connect_options =
      case Keyword.fetch(options, :ifname) do
        {:ok, ifname} ->
          family = ip_to_family(address)
          [ip: ifname_to_ip(ifname, family)]

        :error ->
          []
      end

    case :gen_tcp.connect(address, port, connect_options) do
      {:ok, pid} ->
        :gen_tcp.close(pid)
        {:ok, System.monotonic_time(:microsecond) - start}

      {:error, :econnrefused} ->
        # If the connection is refused, the machine is up.
        {:ok, System.monotonic_time(:microsecond) - start}

      error ->
        error
    end
  end
end
