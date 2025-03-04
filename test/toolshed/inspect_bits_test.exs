# SPDX-FileCopyrightText: 2022 Masatoshi Nishiguchi
# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.InspectBitsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @examples [
    {0,
     """
     Decimal     : 0
     Hexadecimal : 0000_0000
     Octal       : 000
     Binary      : 00000000
     """},
    {255,
     """
     Decimal     : 255
     Hexadecimal : 0000_00FF
     Octal       : 377
     Binary      : 11111111
     """},
    {-1,
     """
     Decimal     : -1
     Hexadecimal : FFFF_FFFF
     Octal       : 37_777_777_777
     Binary      : 11111111_11111111_11111111_11111111
     """},
    {1000,
     """
     Decimal     : 1_000
     Hexadecimal : 0000_03E8
     Octal       : 001_750
     Binary      : 00000011_11101000
     """},
    {19_075_645,
     """
     Decimal     : 19_075_645
     Hexadecimal : 0123_123D
     Octal       : 110_611_075
     Binary      : 00000001_00100011_00010010_00111101
     """},
    {5_000_000_000,
     """
     Decimal     : 5_000_000_000
     Hexadecimal : 0000_0001_2A05_F200
     Octal       : 045_201_371_000
     Binary      : 00000001_00101010_00000101_11110010_00000000
     """},
    {-255,
     """
     Decimal     : -255
     Hexadecimal : FFFF_FF01
     Octal       : 37_777_777_401
     Binary      : 11111111_11111111_11111111_00000001
     """}
  ]

  test "inspect_bits/1" do
    for {input, output} <- @examples do
      assert capture_io(fn -> Toolshed.inspect_bits(input) end) == output
      assert capture_io(fn -> Toolshed.inspect_bits(input + 0.1) end) == output

      dec_input = Integer.to_string(input)
      hex_input = inspect(input, base: :hex)
      octal_input = inspect(input, base: :octal)
      binary_input = inspect(input, base: :binary)

      assert capture_io(fn -> Toolshed.inspect_bits(dec_input) end) == output
      assert capture_io(fn -> Toolshed.inspect_bits(hex_input) end) == output
      assert capture_io(fn -> Toolshed.inspect_bits(octal_input) end) == output
      assert capture_io(fn -> Toolshed.inspect_bits(binary_input) end) == output
    end
  end
end
