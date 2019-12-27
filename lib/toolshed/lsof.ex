defmodule Toolshed.Lsof do
  @moduledoc """
  List out open files by process
  """

  alias Toolshed.Result

  @doc """
  List out open files by process

  ```elixir
  iex> lsof |> grep(~r/erlang/)
  ...
  ```

  This is an simple version of lsof that works on Linux and
  Nerves. While running the normal version of lsof provides
  more information, this can be convenient when lsof isn't
  easily available or can't be run due to `:emfile` errors
  from starting port processes due to too many files being open..
  """
  @spec lsof() :: Result.t()
  def lsof() do
    path_ls("/proc")
    |> Enum.filter(&File.dir?/1)
    |> Enum.map(&lsof_process/1)
    |> Result.new()
  end

  defp lsof_process(path) do
    with {:ok, cmdline} <- File.read(Path.join(path, "cmdline")),
         [cmd | _args] = String.split(cmdline, <<0>>) do
      path_ls(Path.join(path, "fd"))
      |> Enum.map(fn fd_path -> lsof_fd(fd_path, cmd) end)
    else
      _any_error -> []
    end
  end

  defp lsof_fd(fd_path, cmd) do
    case File.read_link(fd_path) do
      {:ok, where} ->
        [where, "\t\t\t", cmd, ?\n]

      _other ->
        []
    end
  end

  defp path_ls(path) do
    case File.ls(path) do
      {:ok, names} ->
        Enum.map(names, fn name -> Path.join(path, name) end)

      _other ->
        []
    end
  end
end
