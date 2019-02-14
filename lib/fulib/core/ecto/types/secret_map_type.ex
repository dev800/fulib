defmodule Fulib.Ecto.SecretMapType do
  @behaviour Ecto.Type

  def type, do: :"Fulib.Ecto.SecretMapType"

  # 格式化到程序到可读性
  def cast(nil), do: {:ok, nil}

  def cast(value) do
    {:ok, value |> Fulib.string_keys_deep!}
  end

  # 从数据库加载到数据可读性
  def load(value) do
    {:ok, value |> _decrypt()}
  end

  # 写入数据库
  def dump(value) do
    {:ok, value |> _encrypt()}
  end

  defp _decrypt(nil), do: %{}

  defp _decrypt(""), do: %{}

  defp _decrypt(value) do
    value |> Fulib.Cipher.decrypt() |> Fulib.from_json(keys: :strings)
  end

  defp _encrypt(value) do
    (value || %{})
    |> Fulib.to_json()
    |> Fulib.Cipher.encrypt()
  end
end
