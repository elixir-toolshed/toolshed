defmodule Toolshed.HTTP do
  @moduledoc false

  @spec url_defaults(URI.t() | binary) :: URI.t() | binary
  def url_defaults(url) do
    case URI.parse(url) do
      %URI{scheme: nil} -> "http://#{url}"
      _ -> url
    end
  end

  @spec display_headers([tuple], binary) :: :ok
  def display_headers(headers, prefix) do
    Enum.each(headers, fn {k, v} ->
      IO.puts(:stderr, "#{prefix} #{k}: #{v}")
    end)
  end

  @spec handle_stream(boolean) :: :ok | nil
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
