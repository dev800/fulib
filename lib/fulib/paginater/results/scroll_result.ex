defmodule Fulib.Paginater.ScrollResult do
  @moduledoc """
  滚动翻页的查询结果
  """

  alias Fulib.Paginater.ScrollResult

  defstruct limit: 0,
            style: :scroll,
            per_page: 20,
            entries: [],
            top_entries: [],
            ext: %{},
            next_cursor: "",
            pre_cursor: "",
            current_cursor: "",
            is_first: true,
            is_last: true

  @type t :: %__MODULE__{}

  defimpl Enumerable, for: ScrollResult do
    def slice(_enumerable), do: {:error, __MODULE__}

    def count(_page), do: {:error, __MODULE__}

    def member?(_page, _value), do: {:error, __MODULE__}

    def reduce(%ScrollResult{entries: entries}, acc, fun) do
      Enumerable.reduce(entries, acc, fun)
    end
  end
end
