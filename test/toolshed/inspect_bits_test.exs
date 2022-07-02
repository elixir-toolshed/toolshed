defmodule Toolshed.InspectBitsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "inspect_bits/1 prints information on number" do
    assert capture_io(fn -> Toolshed.inspect_bits(19_075_645) end) ==
             """
             \e[36mDecimal    \e[0m : 19075645\e[0m
             \e[36mHexadecimal\e[0m : 123123D\e[0m
             \e[36mOctal      \e[0m : 110611075\e[0m
             \e[36mBinary     \e[0m : \e[37m0000000\e[32m1\e[37m | \e[37m00\e[32m1\e[37m000\e[32m11\e[37m | \e[37m000\e[32m1\e[37m00\e[32m1\e[37m0\e[37m | \e[37m00\e[32m1111\e[37m0\e[32m1\e[0m
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
