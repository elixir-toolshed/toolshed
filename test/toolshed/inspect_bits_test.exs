defmodule Toolshed.InspectBitsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "inspect_bits/1 prints information on number" do
    assert capture_io(fn -> Toolshed.inspect_bits(19_075_645) end) ==
             """
             Decimal     : 19075645
             Hexadecimal : 123123D
             Octal       : 110611075
             Binary      : 00000001 | 00100011 | 00010010 | 00111101
             """

    assert Toolshed.inspect_bits(19_075_645) == :"do not show this result in output"
  end

  @expected_conversion_table %{
    decimal: "19075645",
    hex: "123123D",
    octal: "110611075",
    binary: "1001000110001001000111101"
  }

  test "convert_bits/1 with integer" do
    assert Toolshed.convert_bits(19_075_645) == @expected_conversion_table
  end

  test "convert_bits/1 with base 10 string" do
    assert Toolshed.convert_bits("19075645") == @expected_conversion_table
  end

  test "convert_bits/1 with base 16 string" do
    assert Toolshed.convert_bits("0x123123D") == @expected_conversion_table
  end

  test "convert_bits/1 with base 8 string" do
    assert Toolshed.convert_bits("0o110611075") == @expected_conversion_table
  end

  test "convert_bits/1 with base 2 string" do
    assert Toolshed.convert_bits("0b1001000110001001000111101") == @expected_conversion_table
  end
end
