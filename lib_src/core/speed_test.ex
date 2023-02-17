defmodule Toolshed.Core.SpeedTest do
  @typedoc "Options for speed_test/1"
  @type speed_test_options :: [
          duration: pos_integer(),
          ifname: String.t(),
          url: String.t() | URI.t()
        ]

  @doc """
  Perform a download speed test

  Calling this with no options measures the download speed of a small test
  file. The test file may not be large enough or close enough to you to
  produce a good measurement. To fix this, pass a `:url` to a better file. To
  change the default, add the following to your application environment:

  ```elixir
  config :toolshed, speed_test_url: "http://my_company.com/speed_test_file.bin"
  ```

  Commercial users are encouraged to specify their own files to minimize our
  bandwidth costs.

  Please be aware that this function is somewhat simplistic in how it measures
  download performance.

  Options:

  * `:duration` - Maximum duration in milliseconds (defaults to 5 seconds)
  * `:ifname` - Interface to use (e.g., `"wwan0"` or `"eth0"`)
  * `:url` - File to download for the test
  """
  @spec speed_test(speed_test_options()) :: :ok
  def speed_test(options \\ []) do
    default_url = Application.get_env(:toolshed, :speed_test_url)
    url = Keyword.get(options, :url, default_url) |> URI.parse()
    duration = Keyword.get(options, :duration, 5000)

    request = [
      ["GET ", url.path, " HTTP/1.1\r\n"],
      ["Host: ", url.host, "\r\n"],
      "User-Agent: Mozilla/5.0\r\n",
      "\r\n",
      "\r\n"
    ]

    connect_options =
      case Keyword.fetch(options, :ifname) do
        {:ok, ifname} ->
          [ip: ifname_to_ip(ifname, :inet)]

        :error ->
          []
      end

    case :gen_tcp.connect(
           String.to_charlist(url.host),
           url.port,
           [:binary, {:active, true} | connect_options],
           min(5000, duration)
         ) do
      {:ok, s} ->
        :ok = :gen_tcp.send(s, request)
        wait_for_connect(s, duration)
        :gen_tcp.close(s)

      {:error, reason} ->
        IO.puts("Can't connect to #{url.host}: #{inspect(reason)}")
    end
  end

  defp wait_for_connect(s, duration) do
    receive do
      {:tcp, ^s, response} ->
        length = get_length_from_headers(response)
        start_us = System.monotonic_time(:microsecond)
        state = %{s: s, start_us: start_us, end_us: start_us + duration * 1000, length: length}
        loop(state, 0, start_us)

      other ->
        IO.inspect(other)
    after
      5000 ->
        IO.puts("Can't connect to download site")
    end
  end

  defp get_length_from_headers(data) do
    # Split off the beginning of the content
    [header, content] = String.split(data, "\r\n\r\n", parts: 2)

    case Regex.run(~r/Content-Length: (\d+)/, header) do
      [_, content_length] -> String.to_integer(content_length) - byte_size(content)
      _ -> 0
    end
  end

  defp loop(%{length: length} = state, received, _next_status_us) when received >= length do
    now = System.monotonic_time(:microsecond)
    print_report(state, received, now)
  end

  defp loop(state, received, next_status_us) do
    s = state.s

    receive do
      {:tcp, ^s, data} ->
        new_received = received + byte_size(data)

        now = System.monotonic_time(:microsecond)
        next_status_us = update_status(state, new_received, now, next_status_us)

        if now < state.end_us do
          loop(state, new_received, next_status_us)
        else
          print_report(state, new_received, now)
        end

      {:tcp_closed, ^s} ->
        now = System.monotonic_time(:microsecond)
        print_report(state, received, now)

      other ->
        IO.inspect(other)
    after
      5000 ->
        IO.puts("Timed out waiting for a response")
    end
  end

  defp print_report(state, received, now) do
    delta_s = max(now - state.start_us, 1) / 1_000_000
    bps = received * 8 / delta_s

    IO.puts([
      "\r#{received} bytes received in #{Float.round(delta_s, 2)} s\n",
      "Download speed: ",
      format(bps)
    ])
  end

  defp update_status(_state, _received, now, next_status_us) when now < next_status_us do
    next_status_us
  end

  defp update_status(state, received, now, next_status_us) do
    delta_us = max(now - state.start_us, 1)
    bps = received * 8 * 1.0e6 / delta_us
    ["\r-->  ", format(bps), "  "] |> IO.write()

    next_status_us + 1_000_000
  end

  defp format(speed) when speed > 1.0e9, do: "#{Float.round(speed / 1.0e9, 2)} Gbps"
  defp format(speed) when speed > 1.0e6, do: "#{Float.round(speed / 1.0e6, 2)} Mbps"
  defp format(speed) when speed > 1.0e3, do: "#{Float.round(speed / 1.0e3, 2)} Kbps"
  defp format(speed), do: "#{round(speed)} bps"
end
