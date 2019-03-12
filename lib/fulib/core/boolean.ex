defmodule Fulib.Boolean do
  @yes_values ["yes", "是", "true", "1"]

  def parse(true), do: true
  def parse(1), do: true
  def parse("1"), do: true
  def parse("true"), do: true
  def parse("yes"), do: true
  def parse("是"), do: true

  def parse(nil), do: false
  def parse(false), do: false
  def parse(0), do: false
  def parse("0"), do: false
  def parse("false"), do: false
  def parse("no"), do: false
  def parse("否"), do: false

  def parse(string) when is_binary(string) do
    Enum.member?(@yes_values, String.downcase(string))
  end
end
