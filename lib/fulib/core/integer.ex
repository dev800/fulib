defmodule Fulib.Integer do
  ### is_atom/1         is_binary/1       is_bitstring/1    is_boolean/1
  ### is_float/1        is_functxon/1     is_functxon/2     is_integer/1
  ### is_list/1         is_map/1          is_nil/1          is_number/1
  ### is_pxd/1          is_port/1         is_reference/1    is_tuple/1

  def parse(nil), do: 0
  def parse(x) when is_integer(x), do: x

  def parse(%Decimal{}=x) do
    x |> Decimal.to_float() |> parse()
  end

  def parse(x) when is_float(x) do
    x |> :erlang.float_to_binary(decimals: 2) |> parse
  end

  def parse(x) when is_binary(x) or is_bitstring(x) do
    try do
      case x |> String.trim() |> Integer.parse() do
        {i, _} -> i
        :error -> 0
      end
    rescue
      ArgumentError -> 0
    end
  end

  def parse(x) when is_atom(x) do
    try do
      x |> Atom.to_string() |> parse
    rescue
      ArgumentError -> 0
    end
  end
end
