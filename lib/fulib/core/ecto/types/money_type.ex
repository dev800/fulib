defmodule Fulib.Ecto.MoneyType do
  @behaviour Ecto.Type
  @default_currency Application.get_env(:money, :default_currency, :CNY)

  def type, do: :"Fulib.Ecto.MoneyType"

  # 格式化到程序到可读性
  def cast(nil), do: {:ok, nil}

  def cast(value) when is_integer(value) do
    cast(%{amount: value})
  end

  def cast(value) when is_binary(value) do
    value
    |> Jason.decode()
    |> case do
      {:ok, value} ->
        cast(value)

      _ ->
        :error
    end
  end

  def cast(%Money{amount: amount, currency: currency}) do
    {:ok, %Money{amount: amount, currency: currency || @default_currency}}
  end

  def cast(value) when is_map(value) do
    %Money{
      amount: Fulib.get(value, :amount),
      currency: Fulib.get(value, :currency, @default_currency)
    }
    |> cast()
  end

  def cast(_value) do
    :error
  end

  # 从数据库加载到数据可读性
  def load(nil), do: {:ok, nil}

  def load(value) when is_binary(value) do
    value |> _decrypt() |> load()
  end

  def load(value), do: {:ok, value}

  # 写入数据库
  def dump(nil), do: {:ok, nil}
  def dump(value) when is_binary(value), do: {:ok, value}

  def dump(value) do
    value |> _encrypt() |> dump()
  end

  defp _decrypt(nil), do: %{}
  defp _decrypt(""), do: %{}

  defp _decrypt(value) do
    value |> Fulib.from_json(keys: :strings)
  end

  defp _encrypt(value) do
    (value || %{}) |> Fulib.to_json()
  end
end
