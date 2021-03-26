defmodule Toolshed.HTTP do
  @moduledoc """
  Helpers that make HTTP requests
  """

  @doc """
  Display the local weather

  See http://wttr.in/:help for more information.
  """
  @spec weather() :: :"do not show this result in output"
  def weather() do
    check_inets()

    {:ok, {_status, _headers, body}} = :httpc.request('http://v2.wttr.in/?An0')

    body |> :binary.list_to_bin() |> IO.puts()
    IEx.dont_display_result()
  end

  @doc """
  Generate an ASCII art QR code

  See https://github.com/chubin/qrenco.de for more information.
  """
  @spec qr_encode(String.t()) :: :"do not show this result in output"
  def qr_encode(message) do
    check_inets()

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
    check_inets()

    url = url_defaults(url)
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
    |> Task.await()

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

  defp check_inets() do
    case Application.ensure_all_started(:inets) do
      {:ok, _} ->
        :ok

      {:error, _} ->
        raise RuntimeError, """
        :inets can't be started.
        This probably means that it isn't in the OTP release.
        To fix, edit your mix.exs and add :inets to the :extra_applications list.
        """
    end
  end
end
