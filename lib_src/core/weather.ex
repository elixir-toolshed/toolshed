defmodule Toolshed.Core.Weather do
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
  defp get_weather() do
    case :httpc.request(:get, {@weather_url, []}, [ssl: [verify: :verify_none]], []) do
      {:ok, {_status, _headers, body}} ->
        body |> :binary.list_to_bin()

      {:error, reason} ->
        error_message(reason)
    end
  rescue
    e in MatchError -> error_message(e)
  catch
    :exit, reason -> error_message(reason)
  end

  defp error_message(reason) do
    """
    Something went wrong when making an HTTP request.
    #{inspect(reason)}
    """
  end
end
