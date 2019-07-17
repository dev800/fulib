defmodule Fulib.Paginater.AllResult do
  @moduledoc """
  不分页，返回全部结果
  """

  alias Fulib.Paginater.AllResult

  defstruct entries: [],
            total_entries: 0,
            style: :all,
            top_entries: [],
            ext: %{}

  @type t :: %__MODULE__{}

  defimpl Enumerable, for: AllResult do
    def slice(_enumerable), do: {:error, __MODULE__}

    def count(_page), do: {:error, __MODULE__}

    def member?(_page, _value), do: {:error, __MODULE__}

    def reduce(%AllResult{entries: entries}, acc, fun) do
      Enumerable.reduce(entries, acc, fun)
    end
  end
end
