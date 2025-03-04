# SPDX-FileCopyrightText: 2023 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Toolshed.Core.Cmd do
  defmodule SanitizerStream do
    @moduledoc false
    defstruct []

    defimpl Collectable, for: SanitizerStream do
      @moduledoc false

      if System.version() >= "1.16" do
        @impl Collectable
        def into(%SanitizerStream{}) do
          collector_fun =
            fn
              _, {:cont, data} ->
                data
                |> IO.iodata_to_binary()
                |> String.replace_invalid()
                |> IO.write()

              _, _ ->
                :ok
            end

          {:ok, collector_fun}
        end
      else
        # For Elixir 1.15 and earlier, just do what we used to which was to do
        # a raw write and hope for the best.
        @impl Collectable
        def into(%SanitizerStream{}) do
          collector_fun =
            fn
              _, {:cont, data} -> IO.binwrite(data)
              _, _ -> :ok
            end

          {:ok, collector_fun}
        end
      end
    end
  end

  @doc """
  Run a command and return the exit code. This function is intended to be run
  interactively.
  """
  @spec cmd(String.t() | charlist()) :: integer()
  def cmd(str) when is_binary(str) do
    {_collectable, exit_code} =
      System.cmd("sh", ["-c", str],
        stderr_to_stdout: true,
        into: %Toolshed.SanitizerStream{}
      )

    exit_code
  end

  def cmd(str) when is_list(str) do
    str |> to_string() |> cmd()
  end
end
