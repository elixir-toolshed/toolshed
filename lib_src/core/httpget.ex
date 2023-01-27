defmodule Toolshed.Core.Httpget do
  @doc """
  Perform a HTTP GET request for the specified URL

  By default, the results are printed or you can optionally choose to download
  it to a specific location on the file system.

  Options:

  * `:dest` - File path to write the response to. Defaults to printing to the terminal.
  * `:verbose` - Display request and response headers. Disabled by default.
  * `:timeout` - Download timeout. Defaults to 30_000 ms
  """
  @spec httpget(String.t(), dest: Path.t(), verbose: boolean()) ::
          :"do not show this result in output"
  def httpget(url, options \\ []) do
    check_app(:inets)

    url = url_defaults(url)
    dest = Keyword.get(options, :dest, nil)
    verbose = Keyword.get(options, :verbose, false)
    timeout = Keyword.get(options, :timeout, 30_000)

    stream =
      if dest != nil do
        to_charlist(dest)
      else
        :self
      end

    request_headers = [{'User-Agent', 'curl'}]

    if verbose do
      display_headers(request_headers, ">")
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

      handle_stream(verbose)
    end)
    |> Task.await(timeout)

    IEx.dont_display_result()
  end

  defp url_defaults(url) do
    case URI.parse(url) do
      %URI{scheme: nil} -> "http://#{url}"
      _ -> url
    end
  end

  defp display_headers(headers, prefix) do
    Enum.each(headers, fn {k, v} ->
      IO.puts(:stderr, "#{prefix} #{k}: #{v}")
    end)
  end

  defp handle_stream(verbose) do
    receive do
      {:http, {_ref, :stream_start, headers}} ->
        if verbose do
          display_headers(headers, "<")
        end

        handle_stream(verbose)

      {:http, {_ref, :stream, body}} ->
        :ok = IO.binwrite(body)
        handle_stream(verbose)

      {:http, {_ref, :stream_end, _headers}} ->
        IO.puts("")
        nil

      {:http, {_ref, :saved_to_file}} ->
        nil

      other ->
        IO.puts("other message: #{inspect(other)}")
    end
  end
end
