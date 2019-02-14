defmodule Fulib.Marshal do
  def load(value) do
    ExMarshal.decode(value)
  end

  def dump(value) do
    ExMarshal.encode(value)
  end

  defdelegate decode(value), to: __MODULE__, as: :load
  defdelegate encode(value), to: __MODULE__, as: :dump
end
