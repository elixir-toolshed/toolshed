defmodule Toolshed.Core.InspectBits do
  @doc """
  Pretty prints a number in hex, octal and binary

  Example:

  ```
  iex> Toolshed.inspect_bits(123)
  Decimal     : 123
  Hexadecimal : 0000_007B
  Octal       : 173
  Binary      : 01111011
  ```
  """
  @spec inspect_bits(number() | binary()) :: :"do not show this result in output"
  def inspect_bits(value) do
    number = parse_number(value)

    [
      bit_line("Decimal    ", "", Integer.to_string(number) |> add_underscores(3)),
      bit_line("Hexadecimal", "", format_base(number, 16, 16, 32, 32)),
      bit_line("Octal      ", "", format_base(number, 8, 9, 9, 32)),
      bit_line("Binary     ", "", format_base(number, 2, 8, 8, 32))
    ]
    |> IO.ANSI.format()
    |> IO.write()

    IEx.dont_display_result()
  end

  defp format_base(x, base, bits_per_group, pad_to_bits_pos, pad_to_bits_neg) do
    pad_to_bits = if x < 0, do: pad_to_bits_neg, else: pad_to_bits_pos
    bits_per_digit = round(:math.log2(base))
    bits = round_bits(x, pad_to_bits)
    digits_per_group = div(bits_per_group, bits_per_digit)
    total_digits = div(bits, bits_per_digit)

    <<unsigned_x::unsigned-size(bits)>> = <<x::size(bits)>>

    Integer.to_string(unsigned_x, base)
    |> String.pad_leading(total_digits, "0")
    |> add_underscores(digits_per_group)
  end

  defp add_underscores("-" <> number_string, digits_per_group) do
    ["-" | add_underscores(number_string, digits_per_group)]
  end

  defp add_underscores(number_string, digits_per_group) do
    number_string
    |> to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(digits_per_group)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
    |> Enum.intersperse(?_)
  end

  defp round_bits(0, bits_per_group), do: bits_per_group

  defp round_bits(x, bits_per_group) do
    negative_bit = if x < 0, do: 1, else: 0
    bits = x |> abs() |> :math.log2() |> ceil()
    div(bits + negative_bit + bits_per_group - 1, bits_per_group) * bits_per_group
  end

  defp bit_line(label, prefix, value) do
    [:cyan, label, :reset, " : ", :light_white, prefix, :reset, value, ?\n]
  end

  defp parse_number(number) when is_integer(number), do: number
  defp parse_number(number) when is_float(number), do: round(number)
  defp parse_number("-" <> neg_number), do: -parse_number(neg_number)
  defp parse_number("0x" <> hex), do: String.to_integer(hex, 16)
  defp parse_number("0X" <> hex), do: String.to_integer(hex, 16)
  defp parse_number("0o" <> oct), do: String.to_integer(oct, 8)
  defp parse_number("0O" <> oct), do: String.to_integer(oct, 8)
  defp parse_number("0b" <> bin), do: String.to_integer(bin, 2)
  defp parse_number("0B" <> bin), do: String.to_integer(bin, 2)
  defp parse_number(dec) when is_binary(dec), do: String.to_integer(dec)
end
