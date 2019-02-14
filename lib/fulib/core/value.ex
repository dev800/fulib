defmodule Fulib.Value do
  def allow_nil?(conf) do
    conf |> Fulib.get(:allow_nil, true) |> Fulib.to_boolean()
  end

  def filter(value, _conf) do
    value
  end

  def convert_to(value, type, conf \\ [])

  def convert_to(value, nil, _conf) do
    value
  end

  @doc """
  字符串数组，为 ，;, \n \t 分隔的字符数组
  """
  def convert_to(value, :string_array, conf) do
    unless is_nil(value) && allow_nil?(conf) do
      value =
        cond do
          is_list(value) ->
            value

          is_binary(value) or is_atom(value) ->
            value
            |> String.split([",", "，", "\n"], trim: true)
            |> Fulib.compact(presence: true)

          true ->
            value
        end

      convert_to(value, {:array, :string}, conf)
    end
  end

  def convert_to(value, :utc_datetime, conf) do
    cond do
      Fulib.blank?(value) ->
        nil

      is_binary(value) ->
        Timex.parse!(value, "{ISO:Extended}")

      true ->
        value
    end
    |> filter(conf)
  end

  def convert_to(value, :boolean, conf) do
    unless is_nil(value) && allow_nil?(conf) do
      value |> Fulib.to_boolean() |> filter(conf)
    end
  end

  def convert_to(value, :string, conf) do
    unless is_nil(value) && allow_nil?(conf) do
      value |> Fulib.to_s() |> filter(conf)
    end
  end

  def convert_to(value, :atom, conf) do
    unless is_nil(value) && allow_nil?(conf) do
      value |> Fulib.to_atom() |> filter(conf)
    end
  end

  def convert_to(value, :integer, conf) do
    unless is_nil(value) && allow_nil?(conf) do
      value |> Fulib.to_i() |> filter(conf)
    end
  end

  def convert_to(value, :float, conf) do
    unless is_nil(value) && allow_nil?(conf) do
      value |> Fulib.to_f() |> filter(conf)
    end
  end

  def convert_to(value, {:array, type}, conf) do
    unless is_nil(value) && allow_nil?(conf) do
      value
      |> Fulib.to_array()
      |> Enum.map(fn i -> convert_to(i, type, conf) end)
    end
  end

  def convert_to(value, _type, _conf), do: value
end
