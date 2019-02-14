defmodule Fulib.Float do
  def ceiling(float) do
    t = trunc(float)

    case float - t do
      neg when neg < 0 -> t
      pos when pos > 0 -> t + 1
      _ -> t
    end
  end

  def to_binary(value, opts \\ []) do
    :erlang.float_to_binary(value, opts)
  end

  def parse(x) when is_nil(x), do: 0.0
  def parse(x) when is_float(x), do: x

  def parse(%Decimal{} = x) do
    x |> Decimal.to_float()
  end

  def parse(x) when is_integer(x) do
    "#{x}.0" |> String.to_float()
  end

  def parse(x) when is_binary(x) or is_bitstring(x) do
    try do
      x = x |> String.trim()

      negative = x |> String.starts_with?("-")

      x =
        if negative do
          String.trim_leading(x, "-")
        else
          x
        end
        |> String.split(~r{[^0-9.]})
        |> List.first()
        |> String.split(".")
        |> Enum.filter(fn i ->
          i != ""
        end)

      value = "#{Enum.at(x, 0)}.#{Enum.at(x, 1) || 0}" |> String.to_float()

      if negative, do: -value, else: value
    rescue
      ArgumentError -> 0.0
    end
  end

  def parse(x) when is_atom(x) do
    try do
      x |> Atom.to_string() |> parse
    rescue
      ArgumentError -> 0.0
    end
  end

  @doc """
  将其它类型转 float 格式

  ## Params

  * x 待转换的内容
  * opts
    * round 四舍五入的位数
    * ceil 向上舍入的位数
    * floor 向下舍入的位数

  ## Examples

  ```
  iex> parse(1.23, ceil: 1)
  1.3

  iex> parse(1.23)
  1.23
  ```
  """
  def parse(x, opts) do
    parse(x)
    |> Fulib.if_call(opts[:round], fn x ->
      x |> Float.round(opts[:round])
    end)
    |> Fulib.if_call(opts[:ceil], fn x ->
      x |> Float.ceil(opts[:ceil])
    end)
    |> Fulib.if_call(opts[:floor], fn x ->
      x |> Float.floor(opts[:floor])
    end)
  end
end
