defmodule Toolshed.QrEncodeTest do
  use ExUnit.Case

  test "qr_encode/1 returns correct value" do
    assert Toolshed.qr_encode("Nerves") == :"do not show this result in output"
  end

  test "qr_encode_wifi/3 returns correct value" do
    assert Toolshed.qr_encode_wifi("NervesSSID", "NervesIsCool", hidden: false, type: :WPA) ==
             :"do not show this result in output"
  end
end
