# SPDX-FileCopyrightText: 2025 Marc Lainez
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.Core.FakeShell do
  @prompt "fksh> "

  @doc """
  Start an interactive fake shell session.

  The shell reads lines from `IO.gets/1` and delegates command execution to
  `Toolshed.cmd/1`. It is intended for manual use or lightweight integration
  testing where an interactive prompt is convenient.

   Example

      iex> Toolshed.fake_shell()
      Starting fake shell. Type 'exit' to quit.
      fksh> echo hello
      ...

  The function returns `:ok` when the user types `exit`.
  """
  @spec fake_shell() :: :ok
  def fake_shell() do
    IO.puts("Starting fake shell. Type 'exit' to quit.")
    fake_shell_loop()
  end

  defp fake_shell_loop() do
    case IO.gets(@prompt) do
      :eof ->
        :ok

      "exit\n" ->
        :ok

      line ->
        line
        |> String.trim()
        |> exec()

        fake_shell_loop()
    end
  end

  defp exec(""), do: :ok

  defp exec(cmdline) do
    _ = Toolshed.cmd(cmdline)
    :ok
  rescue
    e ->
      IO.puts("error: #{inspect(e)}")
  end
end
