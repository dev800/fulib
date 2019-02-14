defmodule Fulib.String.IdPartition do
  @total_length 12
  @unit_length 3

  def parse(x, total_length \\ @total_length, unit_length \\ @unit_length)
      when is_binary(x) or is_integer(x) do
    x
    |> Fulib.to_s()
    |> String.slice(0, total_length)
    |> do_parse(total_length, unit_length)
  end

  defp do_parse(x, total_length, unit_length) do
    Regex.scan(~r/\w{#{unit_length}}/, String.pad_leading(x, total_length, "0")) |> Enum.join("/")
  end
end
