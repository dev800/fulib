defimpl Fulib.Paginater, for: Ecto.Query do
  import Ecto.Query

  alias Fulib.Paginater.Util
  alias Fulib.Paginater.ScrollResult
  alias Fulib.Paginater.LimitResult
  alias Fulib.Paginater.CountResult
  alias Fulib.Paginater.AllResult

  def paginate(query, repo, params \\ []) do
    _paginate(query, repo, Util.get_opts(params))
  end

  defp _paginate(query, repo, %{page_style: :count} = opts) do
    total_entries = total_entries(query, repo)

    %CountResult{
      offset: opts[:offset],
      entries: entries_with_offset(query, repo, offset: opts[:offset], limit: opts[:limit]),
      # 最大页数
      max_page: opts[:max_page],
      page_number: opts[:page_number],
      per_page: opts[:limit],
      limit: opts[:limit],
      total_entries: total_entries,
      total_pages:
        Util.get_total_pages(
          total_entries,
          limit: opts[:limit],
          page_number: opts[:page_number],
          page_lazy_enable?: opts[:page_lazy_enable?],
          page_lazy_num: opts[:page_lazy_num],
          page_lazy_max: opts[:page_lazy_max]
        ),
      # 懒加载分页：是每一页中，分几次加载
      page_lazy_enable?: opts[:page_lazy_enable?],
      # 每一大页中，小页的页数
      page_lazy_num: opts[:page_lazy_num],
      # 最大的小页数量
      page_lazy_max: opts[:page_lazy_max]
    }
  end

  defp _paginate(query, repo, %{page_style: :scroll} = opts) do
    sort_type = opts[:sort_type]

    conditions =
      cond do
        Fulib.present?(opts[:next_cursor]) -> %{next: Util.parse_page_cursor(opts[:next_cursor])}
        Fulib.present?(opts[:pre_cursor]) -> %{pre: Util.parse_page_cursor(opts[:pre_cursor])}
        true -> Util.parse_page_cursor(opts[:page_cursor])
      end

    scroll_query_fn = Fulib.get(opts, :scroll_query_fn) || fn query, _conditions -> query end

    scroll_query =
      scroll_query_fn.(
        query,
        pre: conditions |> Fulib.get(:pre, %{}) |> Fulib.atom_keys!(),
        next: conditions |> Fulib.get(:next, %{}) |> Fulib.atom_keys!()
      )

    scroll_conditions_fn = Fulib.get(opts, :scroll_conditions_fn) || fn _entry -> nil end

    query =
      case scroll_query do
        %Ecto.Query{} -> scroll_query
        _ -> query
      end

    entries =
      query
      |> limit(^opts[:limit])
      |> repo.all

    next_entry = if sort_type == :desc, do: entries |> List.first(), else: entries |> List.last()
    pre_entry = if sort_type == :desc, do: entries |> List.last(), else: entries |> List.first()

    next_cursor =
      if next_entry do
        %{next: next_entry |> scroll_conditions_fn.()}
      end
      |> Util.encode_page_cursor()

    pre_cursor =
      if pre_entry do
        %{pre: pre_entry |> scroll_conditions_fn.()}
      end
      |> Util.encode_page_cursor()

    %ScrollResult{
      entries: entries,
      limit: opts[:limit],
      per_page: opts[:limit],
      next_cursor: next_cursor,
      pre_cursor: pre_cursor,
      current_cursor: Util.encode_page_cursor(conditions),
      is_first: opts[:is_first],
      is_last: length(entries) < opts[:limit]
    }
  end

  defp _paginate(query, repo, %{page_style: :limit} = opts) do
    %LimitResult{
      entries: entries_with_offset(query, repo, offset: opts[:offset], limit: opts[:limit]),
      limit: opts[:limit],
      per_page: opts[:limit],
      offset: opts[:offset]
    }
  end

  defp _paginate(query, repo, %{page_style: :all} = opts) do
    entries = entries_with_offset(query, repo, offset: opts[:offset], limit: opts[:limit])

    %AllResult{
      entries: entries,
      total_entries: length(entries)
    }
  end

  defp entries_with_offset(query, repo, opts) do
    query
    |> limit(^opts[:limit])
    |> offset(^opts[:offset])
    |> repo.all
  end

  defp total_entries(query, repo) do
    primary_key =
      query.from
      |> case do
        {_table_name, module} ->
          module

        %{source: {_table_name, module}} ->
          module
      end
      |> apply(:__schema__, [:primary_key])
      |> hd

    query
    |> exclude(:order_by)
    |> exclude(:preload)
    |> exclude(:select)
    |> exclude(:group_by)
    |> select([m], count(field(m, ^primary_key), :distinct))
    |> repo.one
  end
end
