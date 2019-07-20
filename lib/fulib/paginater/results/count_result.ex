defmodule Fulib.Paginater.CountResult do
  @moduledoc """
  按照数字进行翻页
  """

  alias Fulib.Paginater.CountResult

  defstruct offset: 0,
            style: :count,
            entries: [],
            top_entries: [],
            ext: %{},
            # 最大页数
            max_page: 0,
            page_number: 1,
            per_page: 20,
            limit: 20,
            total_entries: 0,
            total_pages: 0,
            # 懒加载分页：是每一页中，分几次加载
            page_lazy_enable?: false,
            # 每一大页中，小页的页数
            page_lazy_num: 1,
            # 最大的小页数量
            page_lazy_max: 3,
            # 是否第一页
            is_first: true,
            # 是否最后一页
            is_last: true

  @type t :: %__MODULE__{}

  defimpl Enumerable, for: CountResult do
    def slice(_enumerable), do: {:error, __MODULE__}

    def count(_page), do: {:error, __MODULE__}

    def member?(_page, _value), do: {:error, __MODULE__}

    def reduce(%CountResult{entries: entries}, acc, fun) do
      Enumerable.reduce(entries, acc, fun)
    end
  end
end
