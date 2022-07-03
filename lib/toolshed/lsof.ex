defmodule Toolshed.Lsof do
  @moduledoc false

  def lsof_process(path) do
    with {:ok, cmdline} <- File.read(Path.join(path, "cmdline")),
         [cmd | _args] <- String.split(cmdline, <<0>>) do
      path_ls(Path.join(path, "fd"))
      |> Enum.each(fn fd_path -> lsof_fd(fd_path, cmd) end)
    end
  end

  def lsof_fd(fd_path, cmd) do
    case File.read_link(fd_path) do
      {:ok, where} ->
        IO.puts("#{where}\t\t\t#{cmd}")

      _other ->
        :ok
    end
  end

  def path_ls(path) do
    case File.ls(path) do
      {:ok, names} ->
        Enum.map(names, fn name -> Path.join(path, name) end)

      _other ->
        []
    end
  end
end
