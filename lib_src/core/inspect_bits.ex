defmodule Toolshed.Core.InspectBits do
  @type conversion :: %{
          :binary => binary(),
          :decimal => binary(),
          :hex => binary(),
          :octal => binary()
        }

  @doc """
  Prints out information on the given numeric value.
  """
  @spec inspect_bits(integer | binary) :: :"do not show this result in output"
  def inspect_bits(number) do
    conversion = convert_bits(number)

    [
      [:cyan, "Decimal    ", :reset, " : ", conversion.decimal],
      [:cyan, "Hexadecimal", :reset, " : ", conversion.hex],
      [:cyan, "Octal      ", :reset, " : ", conversion.octal],
      [:cyan, "Binary     ", :reset, " : ", format_base2_string(conversion.binary)]
    ]
    |> Enum.map(&IO.ANSI.format(&1))
    |> Enum.intersperse('\n')
    |> IO.puts()

    IEx.dont_display_result()
  end

  @doc """
  Converts a given number to different representations.
  """
  @spec convert_bits(integer | binary) :: conversion
  def convert_bits(number) when is_binary(number) do
    number |> parse_numeric_string() |> convert_bits()
  end

  def convert_bits(number) when is_integer(number) do
    %{
      decimal: integer_to_string(number, :decimal),
      binary: integer_to_string(number, :binary),
      octal: integer_to_string(number, :octal),
      hex: integer_to_string(number, :hex)
    }
  end

  defp integer_to_string(number, :hex) when is_integer(number) do
    "0x" <> value = inspect(number, base: :hex)
    value
  end

  defp integer_to_string(number, :octal) when is_integer(number) do
    "0o" <> value = inspect(number, base: :octal)
    value
  end

  defp integer_to_string(number, :binary) when is_integer(number) do
    "0b" <> value = inspect(number, base: :binary)
    value
  end

  defp integer_to_string(number, _) when is_integer(number) do
    to_string(number)
  end

  defp parse_numeric_string("0x" <> hex) do
    case Integer.parse(hex, 16) do
      {value, _} -> value
      _ -> nil
    end
  end

  defp parse_numeric_string("0o" <> octal) do
    case Integer.parse(octal, 8) do
      {value, _} -> value
      _ -> nil
    end
  end

  defp parse_numeric_string("0b" <> binary) do
    case Integer.parse(binary, 2) do
      {value, _} -> value
      _ -> nil
    end
  end

  defp parse_numeric_string(decimal) when is_binary(decimal) do
    case Integer.parse(decimal, 10) do
      {value, _} -> value
      _ -> nil
    end
  end

  defp format_base2_string(base2_string) when is_binary(base2_string) do
    string_length = String.length(base2_string)

    byte_count =
      if rem(string_length, 8) == 0 do
        div(string_length, 8)
      else
        div(string_length, 8) + 1
      end

    String.pad_leading(base2_string, byte_count * 8, "0")
    |> to_charlist
    |> Enum.chunk_every(8)
    |> Enum.intersperse(' | ')
    |> Enum.map(fn byte ->
      byte
      |> Enum.chunk_by(fn bit -> bit == ?1 end)
      |> Enum.map(fn
        [?1 | _] = chunk -> [:green, chunk]
        chunk -> [:white, chunk]
      end)
    end)
  end
end
