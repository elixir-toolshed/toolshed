defmodule Toolshed.Core.History do
  @doc """
  Print out the IEx shell history

  The default is to print the history from the current group leader, but
  any group leader can be passed in if desired.
  """
  @spec history(pid()) :: :"do not show this result in output"
  def history(gl \\ Process.group_leader()) do
    commands = last_commands(gl)
    format = format_spec(length(commands))

    commands
    |> Enum.with_index(1)
    |> Enum.map(fn {line, index} -> :io_lib.format(format, [index, line]) end)
    |> IO.puts()

    :"do not show this result in output"
  end

  defp last_commands(gl) do
    case get_in(Process.info(gl), [:dictionary, :line_buffer]) do
      nil -> []
      list -> Enum.reverse(list)
    end
  end

  defp format_spec(highest_number) do
    number_size = :math.log10(highest_number + 1) |> ceil()
    '~#{number_size}B  ~ts'
  end
end
