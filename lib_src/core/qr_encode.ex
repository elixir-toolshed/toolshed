defmodule Toolshed.Core.QrEncode do
  @doc """
  Generate an ASCII art QR code

  See https://github.com/chubin/qrenco.de for more information.
  """
  @spec qr_encode(String.t()) :: :"do not show this result in output"
  def qr_encode(message) do
    check_app(:inets)

    encoded = message |> URI.encode() |> to_charlist()
    form_data = [?x, ?= | encoded]

    {:ok, {_status, _headers, body}} =
      :httpc.request(
        :post,
        {~c"http://qrenco.de/", [{~c"User-Agent", ~c"curl"}],
         ~c"application/x-www-form-urlencoded", form_data},
        [],
        []
      )

    body |> :binary.list_to_bin() |> IO.puts()
    IEx.dont_display_result()
  end

  @doc """
  Generate an ASCII art QR code for WiFi connections

  See https://en.wikipedia.org/wiki/QR_code#Joining_a_Wi%E2%80%91Fi_network
  for string format
  """
  @type wifi_opt :: {:hidden, boolean()} | {:type, :WPA | :WEP | :nopass}
  @spec qr_encode_wifi(String.t(), String.t(), [wifi_opt()]) ::
          :"do not show this result in output"
  def qr_encode_wifi(ssid, psk, opts \\ []) do
    type = opts[:type] || "WPA"
    hidden = opts[:hidden] || false
    msg = "WIFI:S:#{ssid};T:#{type};P:#{psk};H:#{hidden};;"
    qr_encode(msg)
  end
end
