defmodule Toolshed.Core.Cmd do
  @doc """
  Run a command and return the exit code. This function is intended to be run
  interactively.
  """
  @spec cmd(String.t() | charlist()) :: integer()
  def cmd(str) when is_binary(str) do
    {_collectable, exit_code} =
      System.cmd("sh", ["-c", str], stderr_to_stdout: true, into: IO.binstream(:stdio, :line))

    exit_code
  end

  def cmd(str) when is_list(str) do
    str |> to_string |> cmd
  end
end
