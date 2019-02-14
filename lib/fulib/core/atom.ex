defmodule Fulib.Atom do
  def parse(nil), do: nil
  def parse(value), do: :"#{value}"

  def blank?(value) do
    Fulib.String.blank?(value)
  end

  def trim_trailing(atom) do
    atom |> Fulib.to_s() |> String.trim_trailing() |> Fulib.to_atom()
  end

  def trim_trailing(atom, to_trim) do
    atom |> Fulib.to_s() |> String.trim_trailing(to_trim) |> Fulib.to_atom()
  end

  def pluralize(word) do
    word
    |> Fulib.to_s()
    |> Fulib.String.pluralize()
    |> Fulib.to_atom()
  end

  def singularize(word) do
    word
    |> Fulib.to_s()
    |> Fulib.String.singularize()
    |> Fulib.to_atom()
  end
end
