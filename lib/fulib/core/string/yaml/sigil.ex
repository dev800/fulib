defmodule Fulib.String.Yaml.Sigil do
  def sigil_y(string, [?a]), do: Fulib.String.Yaml.Decoder.read_from_string(string, atoms: true)

  def sigil_y(string, []), do: Fulib.String.Yaml.Decoder.read_from_string(string)
end
