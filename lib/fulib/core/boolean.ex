defmodule Fulib.Boolean do
  def parse(nil), do: false
  def parse(true), do: true
  def parse(1), do: true
  def parse("1"), do: true
  def parse("true"), do: true
  def parse(false), do: false
  def parse(0), do: false
  def parse("0"), do: false
  def parse("false"), do: false

  def parse(string, right \\ "是") do
    if string == right, do: true, else: false
  end
end
