defmodule Fulib.Paginater.LimitResult do
  @moduledoc """
  根据偏移量进行查询
  """

  alias Fulib.Paginater.LimitResult

  defstruct entries: [],
            style: :limit,
            top_entries: [],
            ext: %{},
            limit: 20,
            per_page: 20,
            offset: 0,
            # 是否第一页
            is_first: true,
            # 是否最后一页
            is_last: true

  @type t :: %__MODULE__{}

  defimpl Enumerable, for: LimitResult do
    def slice(_enumerable), do: {:error, __MODULE__}

    def count(_page), do: {:error, __MODULE__}

    def member?(_page, _value), do: {:error, __MODULE__}

    def reduce(%LimitResult{entries: entries}, acc, fun) do
      Enumerable.reduce(entries, acc, fun)
    end
  end
end
