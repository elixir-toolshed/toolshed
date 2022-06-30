defmodule Toolshed.Weather do
  @moduledoc """
  This module provides the `weather` command
  """

  import Toolshed.Utils, only: [check_app: 1]

  @weather_url 'https://v2.wttr.in/?An0'

  @doc """
  Display the local weather

  See http://wttr.in/:help for more information.
  """
  @spec weather() :: :"do not show this result in output"
  def weather() do
    check_app(:inets)
    check_app(:ssl)

    {:ok, {_status, _headers, body}} =
      :httpc.request(:get, {@weather_url, []}, [ssl: [verify: :verify_none]], [])

    body |> :binary.list_to_bin() |> IO.puts()
    IEx.dont_display_result()
  rescue
    # unexpected response
    _ in MatchError ->
      raise RuntimeError, """
      Something went wrong when making an HTTP request.
      """
  catch
    # :httpc server crashed
    :exit, _ ->
      raise RuntimeError, """
      Something went wrong when making an HTTP request.
      """
  end
end
