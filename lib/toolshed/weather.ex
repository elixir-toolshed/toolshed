defmodule Toolshed.Weather do
  @moduledoc ""

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

    get_weather() |> IO.puts()
    IEx.dont_display_result()
  end

  @doc false
  @spec get_weather() :: binary
  def get_weather() do
    case :httpc.request(:get, {@weather_url, []}, [ssl: [verify: :verify_none]], []) do
      {:ok, {_status, _headers, body}} ->
        body |> :binary.list_to_bin()

      {:error, reason} ->
        """
        Something went wrong when making an HTTP request.
        #{inspect(reason)}
        """
    end
  catch
    :exit, reason ->
      """
      Something went wrong when making an HTTP request.
      #{inspect(reason)}
      """
  end
end
