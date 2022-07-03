defmodule Toolshed.History do
  @moduledoc false

  def last_commands(gl) do
    case get_in(Process.info(gl), [:dictionary, :line_buffer]) do
      nil -> []
      list -> Enum.reverse(list)
    end
  end

  def format_spec(highest_number) do
    number_size = :math.log10(highest_number + 1) |> ceil()
    '~#{number_size}B  ~ts'
  end
end
