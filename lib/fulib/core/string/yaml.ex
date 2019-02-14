defmodule Fulib.String.Yaml do
  def decode!(str, opts \\ []) do
    Fulib.String.Yaml.Decoder.read_from_string(str, opts)
  end

  def encode!(data, opts \\ []) do
    Fulib.String.Yaml.Encoder.encode(data, opts)
  end
end
