defmodule Toolshed.Weather do
  @moduledoc false

  @weather_url 'https://v2.wttr.in/?An0'

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
