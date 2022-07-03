defmodule Toolshed.Top do
  @moduledoc false

  @default_rows 23
  @default_columns 80

  def rows() do
    case :io.rows() do
      {:ok, rows} -> rows
      _ -> @default_rows
    end
  end

  def columns() do
    case :io.columns() do
      {:ok, columns} -> columns
      _ -> @default_columns
    end
  end
end
