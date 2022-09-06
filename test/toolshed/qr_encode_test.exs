defmodule Toolshed.QrEncodeTest do
  use ExUnit.Case
  import Toolshed.QrEncode

  test "qr_encode/1 returns correct value" do
    assert qr_encode("Nerves") == :"do not show this result in output"
  end
end
