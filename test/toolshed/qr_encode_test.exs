defmodule Toolshed.QrEncodeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Toolshed.QrEncode

  test "Toolshed.h/1 macro prints doc" do
    use Toolshed
    assert capture_io(fn -> h(qr_encode) end) |> String.match?(~r/def qr_encode/)
  end

  test "qr_encode/1 returns correct value" do
    assert qr_encode("Nerves") == :"do not show this result in output"
  end
end
