defmodule Fulib.Ecto.StringType do
  @behaviour Ecto.Type

  def type, do: :"Fulib.Ecto.StringType"

  def cast(nil), do: {:ok, nil}

  def cast(value) do
    {:ok, value |> Fulib.to_s()}
  end

  # 从数据库加载到数据可读性
  def load(value) do
    {:ok, value |> Fulib.to_s()}
  end

  # 写入数据库
  def dump(value) do
    {:ok, Fulib.to_s(value)}
  end
end
