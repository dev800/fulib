defmodule Fulib.Ecto.SecretType do
  @behaviour Ecto.Type

  def type, do: :"Fulib.Ecto.SecretType"

  # 格式化到程序到可读性
  def cast(value) do
    {:ok, value |> Fulib.to_s()}
  end

  # 从数据库加载到数据可读性
  def load(value) do
    {:ok, value |> _decrypt()}
  end

  # 写入数据库
  def dump(value) do
    {:ok, value |> _encrypt()}
  end

  defp _decrypt(value) do
    value |> Fulib.Cipher.decrypt()
  end

  defp _encrypt(value) do
    value
    |> Fulib.to_s()
    |> Fulib.Cipher.encrypt()
  end
end
