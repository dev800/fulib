defmodule Fulib.String.PlainFormat do
  @moduledoc """
  纯文本格式的正文的转换
  """

  alias Fulib.HtmlSanitize
  alias Fulib.HTMLParse

  @auto_link_schemas ~w(mailto http https thunder ftp sftp svn)

  def auto_link_schemas, do: @auto_link_schemas

  @doc """
  转成html
  ## opts
  ```
  * sanitize true/false 是否过滤标签
  * wrapper_tag: :p or :br 默认:p
  ```
  """
  def to_html(text, opts \\ []) do
    wrapper_tag = opts |> Keyword.get(:wrapper_tag, :p) |> Fulib.to_atom()
    sanitize = opts |> Keyword.get(:sanitize, false)

    text = if sanitize, do: HtmlSanitize.strip_tags(text), else: text
    text = Fulib.to_s(text)

    paragraphs = split_paragraphs(text)

    if Fulib.blank?(paragraphs) do
      case wrapper_tag do
        :br -> "<p></p>"
        _ -> "<#{wrapper_tag}></#{wrapper_tag}>"
      end
    else
      new_paragraphs =
        paragraphs
        |> Enum.map(fn paragraph ->
          Enum.map(paragraph, fn p ->
            "#{Fulib.html_escape(p)}"
          end)
          |> Enum.filter(fn p -> Fulib.present?(p) end)
          |> Enum.join("<br />")
        end)
        |> Enum.filter(fn paragraph -> Fulib.present?(paragraph) end)

      case wrapper_tag do
        :br ->
          new_paragraphs |> Enum.join("<br />")

        _ ->
          new_paragraphs
          |> Enum.map(fn paragraph ->
            "<#{wrapper_tag}>#{paragraph}</#{wrapper_tag}>"
          end)
          |> Enum.join("")
      end
    end
  end

  def split_paragraphs(text) do
    if Fulib.blank?(text) do
      text
    else
      text
      # 将\r\n 换成一个\n
      |> String.replace(~r/\r\n?/, "\n")
      # 多个换行换成一个换行
      |> String.split(~r/\n\n+/)
      |> Enum.map(fn t -> String.split(t, ~r/\n/) end)
    end
  end

  @doc """
  将纯文本中的url转换成HTML链接
  """
  def auto_link(plain_text, extends \\ %{}, opts \\ []) do
    Fulib.Const.scan_url_regex()
    |> Regex.replace(plain_text, fn link_url, _ ->
      {
        "a",
        normalize_linker_attrs([{"href", normalize_href(link_url, opts)}], opts),
        normalize_linker_rest([link_url], opts)
      }
      |> transform_linker(extends, opts)
      |> HTMLParse.raw_html()
    end)
  end

  @doc """
  对标签属性的处理
  opts:
    * target
  """
  def normalize_linker_attrs(attrs, opts) do
    parsed_attrs = HTMLParse.parse_attrs(attrs)
    html_opts = opts |> Keyword.get(:html, %{})
    target = html_opts |> Map.get(:target, nil)

    parsed_attrs =
      if Enum.member?(["_blank", "_parent", "_self"], target) do
        parsed_attrs |> Keyword.put(:target, target)
      else
        parsed_attrs |> Keyword.drop([:target])
      end

    parsed_attrs |> HTMLParse.flatten_attrs()
  end

  @doc "实现格式化rest"
  def normalize_linker_rest(rest, opts) do
    normalize_rest_fn = opts |> Keyword.get(:normalize_rest_fn, nil)

    if is_function(normalize_rest_fn) do
      normalize_rest_fn.(rest)
    else
      rest
    end
  end

  defp normalize_url(url) do
    url =
      cond do
        Fulib.blank?(url) ->
          ""

        String.starts_with?(url, ["/"]) ->
          url

        true ->
          header_str =
            url |> String.trim() |> String.split(["://"]) |> List.first() |> String.downcase()

          cond do
            Enum.member?(auto_link_schemas(), header_str) -> url
            Regex.match?(Fulib.Const.match_url_regex(), url) -> "http://" <> url
            true -> "/#{url}"
          end
      end

    url |> Fulib.html_unescape()
  end

  # 实现格式化href
  defp normalize_href(url, opts) do
    normalize_href_fn = opts |> Keyword.get(:normalize_href_fn, nil)

    if is_function(normalize_href_fn) do
      url
      |> normalize_href_fn.()
      |> normalize_url
    else
      url = normalize_url(url)

      jump_to_base_uri = Keyword.get(opts, :jump_to, nil)
      jump_fn = Keyword.get(opts, :jump_fn, nil)

      cond do
        is_function(jump_fn) ->
          jump_fn.(url)

        Fulib.present?(jump_to_base_uri) ->
          jump_to_base_uri <> URI.encode_www_form(url)

        true ->
          url
      end
    end
  end

  def transform_linker({"a", attrs, rest}, extends, opts) do
    if is_function(normalize_linker_fn = Fulib.get(opts, :normalize_linker_fn, nil)) do
      normalize_linker_fn.(
        attrs: attrs,
        rest: rest,
        extends: extends,
        opts: opts
      )
    else
      {"a", attrs, rest}
    end
  end
end
