defmodule Fulib.Process do
  def fetch(key), do: fetch(key, fn -> nil end)

  def fetch(key, missing_fn) do
    key
    |> Process.get()
    |> case do
      nil ->
        value = missing_fn.()
        Process.put(key, value)
        value

      value ->
        value
    end
  end
end
