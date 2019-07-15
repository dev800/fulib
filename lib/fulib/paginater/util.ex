defmodule Fulib.Paginater.Util do
  alias Fulib.Paginater.CountResult
  alias Fulib.Paginater.ScrollResult

  @default_opts [
    # 每页条数
    limit: 20,
    # 页数
    page_number: 1,
    # 偏移量: 只对page_style=:limit有效
    offset: 0,
    # 翻页形式：:count（有数量）, :scroll (滚动式)
    page_style: :count,
    # 是否开启懒加载分页
    page_lazy_enable?: false,
    # 懒加载分页当前的页数
    page_lazy_num: 1,
    # 懒加载分页最大的页数
    page_lazy_max: 3,
    # 最大分页数，0 表示不设置上限
    max_page: 0,
    # 默认排序: 默认倒序
    sort_type: :desc
  ]

  def get_limit(opts \\ []) do
    opts
    |> Fulib.get(:limit, @default_opts[:limit], @default_opts[:limit])
    |> Fulib.to_i()
    |> Fulib.as_range(0, get_max_limit(opts))
  end

  def get_max_limit(params) do
    params |> Fulib.get(:max_limit, 1000, 1000) |> Fulib.to_i()
  end

  def get_max_page(params) do
    params
    |> Fulib.get(:max_page, @default_opts[:max_page])
    |> Fulib.to_i()
  end

  @doc """
  根据分页参数，返回相应的值

  ## params

  * `offset`
  * `limit`
  * `page` or `page_number`
  * `page_style` :count, :scroll, :limit, :all
  """
  def get_opts(params \\ []) do
    params
    |> Fulib.atom_keys!()
    |> Map.new()
    |> Map.put(:page_number, Fulib.get_or(params, [:page, :page_number]))
    |> Fulib.reverse_merge(@default_opts)
    |> parse_opts
  end

  def parse_opts(%{page_style: :count} = params) do
    limit = get_limit(params)
    page_number = params |> Fulib.get(:page_number, @default_opts[:page_number]) |> Fulib.to_i()
    page_number = if page_number < 1, do: 1, else: page_number

    page_lazy_enable? =
      params
      |> Fulib.get(:page_lazy_enable?, @default_opts[:page_lazy_enable?])
      |> Fulib.to_boolean()

    page_lazy_max =
      params |> Fulib.get(:page_lazy_max, @default_opts[:page_lazy_max]) |> Fulib.to_i()

    page_lazy_num =
      params |> Fulib.get(:page_lazy_num, @default_opts[:page_lazy_num]) |> Fulib.to_i()

    page_lazy_num = if page_lazy_num > page_lazy_max, do: page_lazy_max, else: page_lazy_num

    offset =
      if page_lazy_enable? do
        (page_number - 1) * page_lazy_max * limit + (page_lazy_num - 1) * limit
      else
        limit * (page_number - 1)
      end

    %{
      limit: limit,
      offset: offset,
      page_number: page_number,
      page_style: :count,
      page_lazy_enable?: page_lazy_enable?,
      page_lazy_max: page_lazy_max,
      page_lazy_num: page_lazy_num,
      max_page: get_max_page(params)
    }
  end

  def parse_opts(%{page_style: :scroll} = params) do
    limit = get_limit(params)

    is_first =
      Fulib.blank?(params[:next_cursor]) and Fulib.blank?(params[:pre_cursor]) and
        Fulib.blank?(params[:current_cursor])

    %{
      limit: limit,
      scroll_conditions_fn: params[:scroll_conditions_fn],
      scroll_query_fn: params[:scroll_query_fn],
      next_cursor: params[:next_cursor],
      pre_cursor: params[:pre_cursor],
      sort_type: params[:sort_type],
      current_cursor: params[:current_cursor],
      page_style: :scroll,
      is_first: is_first
    }
  end

  def parse_opts(%{page_style: :limit} = params) do
    limit = get_limit(params)

    offset =
      if page_number = params[:page_number] do
        page_number = page_number |> Fulib.to_i()
        page_number = if page_number < 1, do: 1, else: page_number
        limit * (page_number - 1)
      else
        params |> Fulib.get(:offset, @default_opts[:offset]) |> Fulib.to_i()
      end

    %{
      limit: limit,
      offset: offset,
      page_style: :limit
    }
  end

  # 说是全部，但还是不给全部
  def parse_opts(%{page_style: :all}) do
    %{
      limit: 20_000,
      offset: 0,
      page_style: :all
    }
  end

  def get_total_pages(total_entries, opts \\ []) do
    limit = get_limit(opts)
    page_lazy_enable? = opts[:page_lazy_enable?] |> Fulib.to_boolean()
    page_lazy_max = opts[:page_lazy_max] |> Fulib.to_i()

    if page_lazy_enable? do
      if limit <= 0 or page_lazy_max <= 0 do
        total_entries
      else
        ceiling(total_entries / limit / page_lazy_max)
      end
    else
      if limit <= 0 do
        total_entries
      else
        ceiling(total_entries / limit)
      end
    end
  end

  def ceiling(float) do
    t = trunc(float)

    case float - t do
      neg when neg < 0 -> t
      pos when pos > 0 -> t + 1
      _ -> t
    end
  end

  def encode_page_cursor(conditions) when is_list(conditions) do
    conditions |> Map.new() |> encode_page_cursor
  end

  def encode_page_cursor(conditions) when is_map(conditions) do
    if Fulib.present?(conditions) do
      base64_string =
        conditions
        |> Fulib.to_json()
        |> Base.encode64()

      ["base64", base64_string] |> Enum.join("-")
    else
      ""
    end
  end

  def encode_page_cursor(_), do: ""

  def parse_page_cursor(conditions) when is_list(conditions) do
    conditions |> Map.new() |> parse_page_cursor
  end

  def parse_page_cursor(conditions) when is_map(conditions) do
    conditions |> Fulib.atom_keys!()
  end

  def parse_page_cursor(page_cursor) do
    case page_cursor |> Fulib.to_s() |> String.split("-") do
      ["base64", tails] ->
        tails
        |> Base.decode64!()
        |> Fulib.from_json()
        |> parse_page_cursor

      _ ->
        parse_page_cursor(%{})
    end
  end

  def has_next_lazy?(%CountResult{} = paginater) do
    %{
      page_lazy_enable?: page_lazy_enable?,
      total_entries: total_entries,
      per_page: per_page,
      page_number: page_number,
      page_lazy_num: page_lazy_num,
      page_lazy_max: page_lazy_max
    } = paginater

    page_lazy_enable? && page_lazy_num < page_lazy_max &&
      total_entries > (page_number - 1) * page_lazy_max + page_lazy_num * per_page
  end

  def has_next?(%CountResult{total_pages: total_pages, page_number: page_number}) do
    total_pages > page_number
  end

  def has_next?(%ScrollResult{entries: entries, limit: limit}) do
    limit > 0 && length(entries) >= limit
  end

  def has_next?(_), do: false
end
