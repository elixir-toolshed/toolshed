# SPDX-FileCopyrightText: 2024 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.Core.Geo do
  @whenwhere_url "http://whenwhere.nerves-project.org/"

  @doc """
  Geo-locate this Elixir instance

  Options:

  * `:ifname` - Network interface to use (e.g., `"eth0"`)
  * `:whenwhere_url` - URL for the whenwhere server to query. Defaults to http://whenwhere.nerves-project.org
  * `:timeout` - Milliseconds to wait for a response. Defaults to 10_000.
  * `:connect_timeout` - Milliseconds to wait for the connection. Defaults to `:timeout` value
  """
  @spec geo(keyword()) :: :"do not show this result in output"
  def geo(options \\ []) do
    check_app(:inets)
    check_app(:ssl)

    do_geo(options) |> IO.puts()
    IEx.dont_display_result()
  end

  defp do_geo(options) do
    url = Keyword.get(options, :whenwhere_url, @whenwhere_url)
    timeout = Keyword.get(options, :timeout, 10_000)
    connect_timeout = Keyword.get(options, :connect_timeout, timeout)

    request_headers = [
      {~c"user-agent", ~c"toolshed"},
      {~c"content-type", ~c"application/x-erlang-binary"}
    ]

    case :httpc.request(
           :get,
           {url, request_headers},
           [ssl: [verify: :verify_none], connect_timeout: connect_timeout, timeout: timeout],
           socket_opts: socket_opts(options)
         ) do
      {:ok, {_status, _headers, body}} ->
        body |> :erlang.list_to_binary() |> :erlang.binary_to_term() |> format_geo_output()

      {:error, reason} ->
        error_message(reason)
    end
  rescue
    e in MatchError -> error_message(e)
  catch
    :exit, reason -> error_message(reason)
  end

  defp extract_ip(ip_port_string) do
    case Regex.run(~r/^(.*):\d+$/, ip_port_string) do
      [_, ip_address] -> ip_address
      _ -> []
    end
  end

  defp format_geo_output(result) do
    now = NaiveDateTime.from_iso8601!(result["now"])

    local_now =
      with {:ok, time_zone} <- Map.fetch(result, "time_zone"),
           {:ok, utc} <- DateTime.from_naive(now, "Etc/UTC"),
           {:ok, dt} <- DateTime.shift_zone(utc, time_zone) do
        dt
      else
        _ -> nil
      end

    where =
      [result["city"], result["country_region"], result["country"]]
      |> Enum.filter(&Function.identity/1)
      |> Enum.intersperse(", ")

    [
      "UTC Time  : ",
      NaiveDateTime.to_string(now),
      "\n",
      if(local_now, do: ["Local time: ", DateTime.to_string(local_now), "\n"], else: []),
      ["Location  : ", where, "\n"],
      if(result["latitude"] && result["longitude"],
        do: [
          "Map       : https://www.openstreetmap.org/?mlat=",
          result["latitude"],
          "&mlon=",
          result["longitude"],
          "&zoom=12#map=12/",
          result["latitude"],
          "/",
          result["longitude"],
          "\n"
        ],
        else: []
      ),
      if(result["address"], do: ["Public IP : ", extract_ip(result["address"])], else: [])
    ]
  end
end
