defmodule Toolshed.HTTP do
  @moduledoc false

  def url_defaults(url) do
    case URI.parse(url) do
      %URI{scheme: nil} -> "http://#{url}"
      _ -> url
    end
  end

  def display_headers(headers, prefix) do
    Enum.each(headers, fn {k, v} ->
      IO.puts(:stderr, "#{prefix} #{k}: #{v}")
    end)
  end

  def handle_stream(verbose \\ false) do
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
