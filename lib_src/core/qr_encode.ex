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
        {'http://qrenco.de/', [{'User-Agent', 'curl'}], 'application/x-www-form-urlencoded',
         form_data},
        [],
        []
      )

    body |> :binary.list_to_bin() |> IO.puts()
    IEx.dont_display_result()
  end
end
