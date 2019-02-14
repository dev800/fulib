defmodule Fulib.LinkerUtil do
  alias Fulib.HTMLParse
  alias Fulib.String.PlainFormat

  @doc """
  返回html中链接的个数
  """
  def links_count(html) do
    html |> HTMLParse.parse() |> HTMLParse.find("a") |> length
  end

  def append_rest(rest, extend_rest) do
    rest |> List.insert_at(-1, extend_rest)
  end

  @doc """
  自动生成链接

  ## opts

  * `html`: 生成链接相关参数
    * :`target` # _blank or nil (nil)
  * `sanitize` 是否过滤标签 true/false 默认为false
  * `sanitize_options` 过滤标签的参数
  * `jump_to` # 用于跳转的基础url
  * `jump_fn` # 调用的时候可以用此回调
  * `html_escape` # true/false # 默认为false
  * `format`
    - :safe 
    - :raw  默认
    - :tree
  * `normalize_rest_fn`   # 格式化链接内容的方法
  * `normalize_href_fn`   # 格式化链接链接的方法
  * `normalize_linker_fn` # 格式化链接, 可以灵活的转换链接！
  """
  def auto_link(html_or_tree, opts \\ []) do
    opts =
      opts
      |> Keyword.take([
        :raw_html,
        :jump_to,
        :jump_fn,
        :html_safe,
        :normalize_rest_fn,
        :normalize_href_fn,
        :normalize_linker_fn
      ])
      |> Fulib.reverse_merge(
        html_raw: true,
        format: :raw,
        html_escape: false,
        html: %{}
      )

    rebuild_html_tree =
      html_or_tree
      |> HTMLParse.parse()
      |> HTMLParse.transform(fn html_node, extends ->
        _transform(html_node, extends, opts)
      end)

    opts
    |> Fulib.get(:format, :raw)
    |> case do
      :tree ->
        rebuild_html_tree

      :safe ->
        {:safe, rebuild_html_tree |> HTMLParse.raw_html()}

      _ ->
        rebuild_html_tree |> HTMLParse.raw_html()
    end
  end

  # 对A标签的处理
  defp _transform({"a", attrs, rest}, extends, opts) do
    {"a", PlainFormat.normalize_linker_attrs(attrs, opts),
     PlainFormat.normalize_linker_rest(rest, opts)}
    |> PlainFormat.transform_linker(extends, opts)
  end

  defp _transform(plain_text, extends, opts) when is_binary(plain_text) do
    _transform_plain_text(plain_text, extends, opts)
  end

  defp _transform(html_tree, _extends, _opts), do: html_tree

  defp _transform_plain_text(plain_text, %{ancestors: ancestors} = extends, opts) do
    plain_text =
      if Fulib.get(opts, :html_escape, false) do
        Fulib.html_escape(plain_text)
      else
        plain_text
      end

    if Enum.member?(ancestors, "a") do
      plain_text
    else
      PlainFormat.auto_link(plain_text, extends, opts)
    end
  end
end
