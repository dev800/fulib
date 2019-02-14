defmodule Fulib.Paginater.ViewHelper do
  alias Fulib.Paginater.CountResult

  @defaults %{
    # 参数名
    page_param: :page,
    # 分页参数的样式
    param_type: :query,
    with_previous: true,
    with_next: true,
    with_large_next: true,
    with_jump: false,
    with_first: false,
    with_last: false,
    with_first_disabled: true,
    with_previous_disabled: true,
    with_next_disabled: true,
    with_last_disabled: true
  }

  @view_styles [
    default: %{
      with_jump: true,
      with_first: false,
      with_first_disabled: false,
      with_previous: true,
      with_next: true,
      with_last: false,
      with_last_disabled: false,
      nav_style: :ul,
      with_pages: true,
      with_large_next: false,
      window: 3,
      last_right: 5,
      right: 1,
      first_left: 5,
      left: 1
    },
    # 简单分页，用于wap
    simple_default: %{
      nav_style: :table,
      with_pages: false,
      with_large_next: true,
      with_previous_disabled: true,
      with_next_disabled: true
    },
    # 简单分页，有第一页和最后一页
    simple_whole: %{
      nav_style: :table,
      with_pages: false,
      with_large_next: true,
      with_previous_disabled: true,
      with_next_disabled: true,
      with_first_disabled: true,
      with_last_disabled: true
    }
  ]

  @doc """
  HTML分页

  ## paginater %Fulib.Paginater.CountResult{}

  ## opts

  * :`base_uri` # 基础URI
  * :`params`   # 额外的url参数
  * :`style` 基础的分页形式（:default, :simple_default, :simple_whole） 会使用相应style默认的配置
  * :`page_param` 
    * :page,           # 参数名
  * :`param_type`                  # 分页参数的样式
    * :query                      # 分页采用 query 查询
    * :folder                     # 分页采用 REST 风格
  * :`with_previous` true,
  * :`with_next` true,
  * :`with_large_next` true,
  * :`with_jump` false,
  * :`with_first` false,
  * :`with_last` false,
  * :`with_first_disabled` true,
  * :`with_previous_disabled` true,
  * :`with_next_disabled` true,
  * :`with_last_disabled` true
  * :`nav_style` :ul,
  * :`with_pages` true,
  * :`window` 3,
  * :`last_right` 5,
  * :`right` 1,
  * :`first_left` 5,
  * :`left` 1
  """
  def paginate(paginater, opts \\ [])
  def paginate([], _opts), do: ""
  def paginate(%CountResult{total_pages: total_pages}, _opts) when total_pages <= 1, do: ""
  def paginate(%{"totalPages" => totalPages}, _opts) when totalPages <= 1, do: ""
  def paginate(%{totalPages: totalPages}, _opts) when totalPages <= 1, do: ""

  def paginate(paginater, opts) do
    base_uri = opts |> Fulib.get(:base_uri)

    style = Fulib.get(opts, :style, :default, :default) |> Fulib.to_atom()

    # 分页相关配置
    opts =
      @defaults
      |> Fulib.merge(Fulib.get(@view_styles, style) || %{})
      |> Fulib.merge(opts)

    params =
      opts
      |> Fulib.get(:params, %{})
      |> Fulib.atom_keys_deep!()
      |> Map.drop([:_ajax_next_page, :_ajax_refresh, :ajax_next_page, :ajax_refresh])

    opts =
      Fulib.merge(opts, %{
        base_uri: base_uri,
        params: params,
        style: style
      })

    _paginate(paginater, opts)
  end

  defp _paginate(%{"totalPages" => totalPages} = paginater, opts) do
    _paginate(
      %CountResult{
        page_number: paginater["pageNumber"],
        total_entries: paginater["totalEntries"],
        limit: paginater["limit"],
        total_pages: totalPages,
        entries: paginater["entries"],
        max_page: paginater["maxPage"],
        per_page: paginater["perPage"]
      },
      opts
    )
  end

  defp _paginate(%CountResult{} = paginater, opts) do
    style = Fulib.get(opts, :style, :default, :default) |> Fulib.to_atom()

    case Fulib.get(opts, :nav_style) do
      :table ->
        Phoenix.HTML.Tag.content_tag :div, class: "u-pagination u-pagination-#{style}" do
          {:safe, large_next_btn} = get_large_next_linker(paginater, opts)

          {:safe, content} =
            Phoenix.HTML.Tag.content_tag :table, class: "pagination clearfix" do
              Phoenix.HTML.Tag.content_tag :tr do
                ([
                   render_first_page(paginater, :td, opts),
                   render_previous_page(paginater, :td, opts)
                 ] ++
                   render_pages(paginater, :td, opts) ++
                   [
                     render_jump_field(paginater, :td, opts),
                     render_next_page(paginater, :td, opts),
                     render_last_page(paginater, :td, opts)
                   ])
                |> Fulib.compact()
              end
            end

          {:safe, large_next_btn ++ content}
        end

      _ ->
        Phoenix.HTML.Tag.content_tag :nav, class: "u-pagination u-pagination-#{style} clearfix" do
          {:safe, large_next_btn} = get_large_next_linker(paginater, opts)

          {:safe, content} =
            Phoenix.HTML.Tag.content_tag :ul do
              ([
                 render_first_page(paginater, :li, opts),
                 render_previous_page(paginater, :li, opts)
               ] ++
                 render_pages(paginater, :li, opts) ++
                 [
                   render_jump_field(paginater, :li, opts),
                   render_next_page(paginater, :li, opts),
                   render_last_page(paginater, :li, opts)
                 ])
              |> Fulib.compact()
            end

          {:safe, large_next_btn ++ content}
        end
    end
  end

  defp render_jump_field(paginater, tag_name, opts) do
    if Fulib.get(opts, :with_jump) do
      href = get_page_url("__jump_page__", opts)

      Phoenix.HTML.Tag.content_tag tag_name do
        Phoenix.HTML.Tag.content_tag :span do
          [
            Phoenix.HTML.Tag.content_tag :span, class: "l-jump-previous" do
              {:safe, Fulib.i18n("label.paginater.goto")}
            end,
            Phoenix.HTML.Tag.tag(
              :input,
              type: "text",
              class: "l-jump-input",
              value: paginater.page_number,
              "data-max-page": paginater.total_pages,
              "data-jump-href": href
            ),
            Phoenix.HTML.Tag.content_tag :span, class: "l-jump-next" do
              {:safe, Fulib.i18n("label.paginater.page")}
            end
          ]
        end
      end
    end
  end

  defp render_pages(paginater, tag_name, opts) do
    if Fulib.get(opts, :with_pages) do
      Enum.map(_render_pages(paginater, tag_name, opts), fn linker -> linker end)
    else
      []
    end
  end

  defp render_first_page(paginater, tag_name, opts) do
    {text, _page, url} = get_first_linker(paginater, opts)

    cond do
      Fulib.get(opts, :with_first) && paginater.page_number > 1 ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "l-page l-first " do
          Phoenix.HTML.Tag.content_tag :a, href: url, class: "btn" do
            {:safe, text}
          end
        end

      Fulib.get(opts, :with_first_disabled) ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "disabled" do
          Phoenix.HTML.Tag.content_tag :span do
            {:safe, text}
          end
        end

      true ->
        nil
    end
  end

  defp render_previous_page(paginater, tag_name, opts) do
    {text, _page, url} = get_previous_linker(paginater, opts)

    cond do
      Fulib.get(opts, :with_previous) && paginater.page_number > 1 ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "l-page l-previous " do
          Phoenix.HTML.Tag.content_tag :a, href: url, class: "btn" do
            {:safe, text}
          end
        end

      Fulib.get(opts, :with_previous_disabled) ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "disabled l-previous" do
          Phoenix.HTML.Tag.content_tag :a, class: "btn" do
            {:safe, text}
          end
        end

      true ->
        nil
    end
  end

  defp render_next_page(paginater, tag_name, opts) do
    {text, _page, url} = get_next_linker(paginater, opts)

    cond do
      Fulib.get(opts, :with_next) && paginater.page_number < paginater.total_pages ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "l-page l-next" do
          Phoenix.HTML.Tag.content_tag :a, href: url, class: "btn" do
            {:safe, text}
          end
        end

      Fulib.get(opts, :with_next_disabled) ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "disabled l-next" do
          Phoenix.HTML.Tag.content_tag :a, class: "btn" do
            {:safe, text}
          end
        end

      true ->
        nil
    end
  end

  defp render_last_page(paginater, tag_name, opts) do
    {text, _page, url} = get_last_linker(paginater, opts)

    cond do
      Fulib.get(opts, :with_last) && paginater.page_number < paginater.total_pages ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "l-page l-last" do
          Phoenix.HTML.Tag.content_tag :a, href: url, class: "btn" do
            {:safe, text}
          end
        end

      Fulib.get(opts, :with_last_disabled) ->
        Phoenix.HTML.Tag.content_tag tag_name, class: "disabled" do
          Phoenix.HTML.Tag.content_tag :span do
            {:safe, text}
          end
        end

      true ->
        nil
    end
  end

  defp _render_pages(paginater, tag_name, opts) do
    total_pages = paginater.total_pages
    page_number = paginater.page_number
    window = Fulib.get(opts, :window) |> Fulib.to_i()

    left =
      (if(page_number == 1, do: Fulib.get(opts, :first_left), else: Fulib.get(opts, :left)) || 0)
      |> Fulib.to_i()

    right =
      (if(
         page_number == total_pages,
         do: Fulib.get(opts, :last_right),
         else: Fulib.get(opts, :right)
       ) || 0)
      |> Fulib.to_i()

    left_page = Enum.min([1 + left, total_pages])
    right_page = Enum.max([total_pages - right, 1 + left])
    window_left_page = Enum.max([left_page, page_number - window])
    window_right_page = Enum.min([right_page, page_number + window])

    quick_pages =
      if page_number == 1 do
        Enum.filter([10, 20, 30, 50, 100, 200, 300, 500], fn page ->
          page > left_page and page < right_page
        end)
      else
        []
      end

    quick_gapable =
      Enum.any?(quick_pages) &&
        window_left_page - Enum.max([List.last(quick_pages), left_page]) > 1

    ((Enum.to_list(1..left_page) |> Enum.sort()) ++
       [
         if window_left_page - left_page > 1 and total_pages > left_page do
           "gap_001"
         end
       ] ++
       quick_pages ++
       [
         if quick_gapable do
           "gap_002"
         end
       ] ++
       (Enum.to_list(window_left_page..window_right_page) |> Enum.sort()) ++
       [
         if right_page - window_right_page > 1 and right_page < total_pages do
           "gap_003"
         end
       ] ++ (Enum.to_list(right_page..total_pages) |> Enum.sort()))
    |> List.flatten()
    |> Fulib.compact()
    |> Enum.uniq()
    |> Enum.filter(fn page ->
      if is_integer(page) do
        page > 0 and page <= total_pages
      else
        true
      end
    end)
    |> Enum.map(fn page ->
      if is_integer(page) do
        {text, _page, url} = get_page_linker(paginater, page, "#{page}", opts)

        Phoenix.HTML.Tag.content_tag tag_name,
          class: "l-page#{if page == paginater.page_number, do: " active"}" do
          Phoenix.HTML.Link.link({:safe, text}, to: url, class: "btn")
        end
      else
        Phoenix.HTML.Tag.content_tag tag_name, class: "l-page l-gap " do
          Phoenix.HTML.Tag.content_tag :span, class: "btn" do
            "..."
          end
        end
      end
    end)
  end

  defp get_page_linker(_paginater, page, text, opts) do
    page = page |> Fulib.to_i()
    page = if page < 1, do: 1, else: page

    {text, page, get_page_url(page, opts)}
  end

  defp get_first_linker(paginater, opts) do
    get_page_linker(paginater, 1, Fulib.i18n("label.paginater.first_page"), opts)
  end

  defp get_previous_linker(paginater, opts) do
    get_page_linker(
      paginater,
      paginater.page_number - 1,
      Fulib.i18n("label.paginater.previous_page"),
      opts
    )
  end

  defp get_next_linker(paginater, opts) do
    get_page_linker(
      paginater,
      paginater.page_number + 1,
      Fulib.i18n("label.paginater.next_page"),
      opts
    )
  end

  defp get_last_linker(paginater, opts) do
    get_page_linker(
      paginater,
      paginater.total_pages,
      Fulib.i18n("label.paginater.last_page"),
      opts
    )
  end

  defp get_page_url(page, opts) do
    if opts[:page_url_fn] |> is_function do
      opts[:page_url_fn].(page, opts)
    else
      normalize_page_url(page, opts)
    end
  end

  defp get_large_next_linker(paginater, opts) do
    page_lazy_num = paginater.page_lazy_num
    with_large_next? = Fulib.get(opts, :with_large_next)
    has_next_page? = Fulib.Paginater.Util.has_next?(paginater)
    has_next_lazy? = Fulib.Paginater.Util.has_next_lazy?(paginater)
    more_pages? = paginater.total_pages > 1

    if (has_next_page? or has_next_lazy? or more_pages?) and with_large_next? do
      cond do
        has_next_lazy? ->
          {text, _page, url} = get_next_linker(paginater, opts)

          Phoenix.HTML.Tag.content_tag :a,
            href: url,
            class: "l-large-next l-lazy-loading btn btn-default",
            "data-usage": "lazy-loading",
            "data-trigger": "auto",
            "data-params":
              Plug.Conn.Query.encode(%{
                _ajax_next_page: page_lazy_num + 1
              }) do
            {:safe, text}
          end

        has_next_page? ->
          {text, _page, url} = get_next_linker(paginater, opts)

          Phoenix.HTML.Tag.content_tag :a, href: url, class: "l-large-next btn btn-default" do
            {:safe, text}
          end

        true ->
          {:safe, []}
      end
    else
      {:safe, []}
    end
  end

  defp normalize_page_url(page, opts) do
    base_uri = opts[:base_uri] |> Fulib.to_s()
    params = opts[:params]
    page_param = opts[:page_param]
    ignore_page = is_integer(page) && page <= 1

    base_uri =
      cond do
        Fulib.present?(base_uri) ->
          base_uri

        conn = opts[:conn] ->
          query_params = conn.query_string |> Plug.Conn.Query.decode() |> Map.drop(["page"])

          "#{conn.request_path}#{
            if Fulib.present?(query_params), do: "?#{Plug.Conn.Query.encode(query_params)}"
          }"

        true ->
          ""
      end

    url =
      case opts[:param_type] do
        :folder ->
          if ignore_page do
            if Enum.any?(params) do
              if String.contains?(base_uri, "?") do
                "#{base_uri}&#{Plug.Conn.Query.encode(params)}"
              else
                "#{base_uri}?#{Plug.Conn.Query.encode(params)}"
              end
            else
              "#{base_uri}"
            end
          else
            base_uri =
              if String.ends_with?(base_uri, "/") do
                "#{base_uri}#{page_param}-#{page}"
              else
                "#{base_uri}/#{page_param}-#{page}"
              end

            if Enum.any?(params) do
              if String.contains?(base_uri, "?") do
                "#{base_uri}&#{Plug.Conn.Query.encode(params)}"
              else
                "#{base_uri}?#{Plug.Conn.Query.encode(params)}"
              end
            else
              "#{base_uri}"
            end
          end

        _ ->
          if ignore_page do
            if Enum.any?(params = Map.delete(params, page_param)) do
              if String.contains?(base_uri, "?") do
                "#{base_uri}&#{Plug.Conn.Query.encode(params)}"
              else
                "#{base_uri}?#{Plug.Conn.Query.encode(params)}"
              end
            else
              "#{base_uri}"
            end
          else
            if Enum.any?(params = Map.put(params, page_param, page)) do
              if String.contains?(base_uri, "?") do
                "#{base_uri}&#{Plug.Conn.Query.encode(params)}"
              else
                "#{base_uri}?#{Plug.Conn.Query.encode(params)}"
              end
            else
              "#{base_uri}"
            end
          end
      end

    %URI{path: path, query: query} = url |> URI.parse()

    path
    |> Fulib.if_call(Fulib.present?(query), fn path ->
      path <> "?" <> query
    end)
  end
end
