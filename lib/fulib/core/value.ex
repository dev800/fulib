defmodule Fulib.Value do
  @csl_spliter ~r/(\t|\r|\n|,|"，")/

  def allow_nil?(opts) do
    opts |> Fulib.get(:allow_nil, true) |> Fulib.to_boolean()
  end

  def filter(value, _opts) do
    value
  end

  def convert_to(value, type, opts \\ [])

  def convert_to(value, nil, _opts) do
    value
  end

  @doc """
  字符串数组，为 ，;, \n \t 分隔的字符数组

  :csl # description: "Comma-Separated List" do
  """
  def convert_to(value, :csl, opts) do
    unless is_nil(value) && allow_nil?(opts) do
      value =
        cond do
          is_list(value) ->
            value

          is_binary(value) or is_atom(value) ->
            value
            |> String.split(@csl_spliter, trim: true)
            |> Fulib.compact(presence: true)

          true ->
            value
        end

      convert_to(value, {:array, :string}, opts)
    end
  end

  def convert_to(value, :utc_datetime, opts) do
    cond do
      Fulib.blank?(value) ->
        nil

      is_binary(value) ->
        Timex.parse!(value, "{ISO:Extended}")

      true ->
        value
    end
    |> filter(opts)
  end

  def convert_to(value, :boolean, opts) do
    unless is_nil(value) && allow_nil?(opts) do
      value |> Fulib.to_boolean() |> filter(opts)
    end
  end

  def convert_to(value, :string, opts) do
    unless is_nil(value) && allow_nil?(opts) do
      value |> Fulib.to_s() |> filter(opts)
    end
  end

  def convert_to(value, :atom, opts) do
    unless is_nil(value) && allow_nil?(opts) do
      value |> Fulib.to_atom() |> filter(opts)
    end
  end

  def convert_to(value, :integer, opts) do
    unless is_nil(value) && allow_nil?(opts) do
      value |> Fulib.to_i() |> filter(opts)
    end
  end

  def convert_to(value, :float, opts) do
    unless is_nil(value) && allow_nil?(opts) do
      value |> Fulib.to_f() |> filter(opts)
    end
  end

  def convert_to(value, {:array, type}, opts) do
    unless is_nil(value) && allow_nil?(opts) do
      value
      |> Fulib.to_array()
      |> Enum.map(fn i -> convert_to(i, type, opts) end)
    end
  end

  def convert_to(value, _type, _opts), do: value
end
