defmodule Toolshed.Cmd do
  def icmd(cmd, _opts \\ []) do
    gl = Process.group_leader()
    orig_opts = :io.getopts(gl)

    :io.setopts(gl, echo: false, expand_fun: false, binary: false)

    me = self()
    input_pid = spawn(fn -> input_loop(gl, me) end)

    p = Port.open({:spawn, cmd}, [:exit_status, :stream, :use_stdio, :binary])
    loop(p)

    send(input_pid, :quit)
    :io.setopts(gl, orig_opts)
  end

  defp loop(p) do
    receive do
      {:input, char} ->
        IO.puts("pressing '#{<<char>>}'")
        Port.command(p, [char])
        loop(p)

      :input_done ->
        :ok

      {^p, {:data, d}} ->
        IO.write(d)
        loop(p)

      other ->
        IO.inspect(other)
        loop(p)
    end
  end

  defp input_loop(gl, pid) do
    case :io.get_chars(gl, "", 1) do
      :eof ->
        input_loop(gl, pid)

      [2] ->
        send(pid, :input_done)
        :ok

      [char] ->
        send(pid, {:input, translate_key(char)})
        input_loop(gl, pid)

      _ ->
        :ok
    end
  end

  defp translate_key(?\r), do: ?\n
  defp translate_key(k), do: k
end
