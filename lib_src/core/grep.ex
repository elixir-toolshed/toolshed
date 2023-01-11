defmodule Toolshed.Core.Grep do
  @doc """
  Run a regular expression on a file and print the matching lines.

      iex> grep ~r/video/, "/etc/mime.types"

  If colored is enabled for the shell, the matches will be highlighted red.
  """
  @spec grep(Regex.t(), Path.t()) :: :"do not show this result in output"
  def grep(regex, path) do
    File.stream!(path)
    |> Stream.filter(&Regex.match?(regex, &1))
    |> Stream.map(fn line ->
      Regex.replace(regex, line, &IO.ANSI.format([:red, &1]))
    end)
    |> Stream.each(&IO.write/1)
    |> Stream.run()

    IEx.dont_display_result()
  end
end
