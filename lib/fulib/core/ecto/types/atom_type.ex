defmodule Fulib.Ecto.AtomType do
  @behaviour Ecto.Type

  def type, do: :"Fulib.Ecto.AtomType"

  def cast(nil), do: {:ok, nil}

  def cast(value) do
    {:ok, value |> Fulib.to_atom()}
  end

  # 从数据库加载到数据可读性
  def load(value) do
    {:ok, value |> Fulib.to_atom()}
  end

  # 写入数据库
  def dump(value) do
    {:ok, Fulib.to_s(value)}
  end
end
