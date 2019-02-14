defmodule Fulib.String.HTMLFormat do
  @ignore_tags ~w(script style object applet iframe)

  @paragraph_tags ~w(p h1 h2 h3 h4 h5 h6 ol ul table dl dd blockquote dialog figure aside section)

  @block_tags ~w(div address dt li center del article header header footer nav pre legend tr)

  @trailing_whitespace ~r/[ \t]+$/

  @doc """
  转换html文件为纯文本格式

  参数：
  * `html` -html内容或html文件的路径。
  * `opts` -一些配置参数，见下：
    * `is_path` -指定html参数是否为文件路径，默认为：否。
    * `img_replace` -指定遇到图片时替换的内容，默认为：`[图片]`。
    * `hr_replace` -指定遇到`<hr>`标签时的替换内容，默认为：`-`。
    * `hr_count` -指定`<hr>`标签替换长度，默认为：`31`。
    * `li_level_replace` -指定`<li>`标签缩进，默认为：`"  "`，即两个空格。
    * `li_trailing` -指定`<li>`标签前缀，默认为：`"* "`。
    * `out_path` -指定处理结果写入文件的地址，为空则不写。

  ## Example

      iex> html = "<hr>
      ...>         <ul>
      ...>           <li><img src='img.png'></li>
      ...>           <li>一级第二个li标签</li>
      ...>         </ul>"
      iex> opts = [
      ...>   is_path: false,
      ...>   img_replace: "[图片]",
      ...>   hr_replase: "-",
      ...>   hr_count: 31,
      ...>   li_level_replase: "  ",
      ...>   li_trailing: "* "
      ...> ]
      iex> to_plain(html, opts)
      -------------------------------
      * [图片]
      * 一级第二个li标签
  """
  def to_plain(html, opts \\ []) do
    html =
      case opts[:is_path] do
        true ->
          File.read!(html)

        _ ->
          html
      end

    body =
      (html || "")
      |> String.replace(~r/<!Doctype html>/i, "<!doctype html>")
      |> Floki.parse()
      |> forward_to_body()
      |> format_list_level()

    result =
      case is_list(body) do
        true ->
          convert_node_to_plain_text({"body", [], body}, "", opts)

        _ ->
          convert_node_to_plain_text(body, "", opts)
      end
      |> String.trim("\n")
      |> String.replace(~r/\n{3,}/, "\n\n")

    if path = opts[:out_path], do: File.write!(path, result)

    result
  end

  def convert_node_to_plain_text({name, attrs, children}, plain, opts) do
    plain =
      cond do
        Enum.member?(@paragraph_tags, name) ->
          append_paragraph_breaks(plain)

        Enum.member?(@block_tags, name) ->
          append_block_breaks(plain)

        true ->
          plain
      end

    plain =
      if name == "li",
        do: format_list_item(plain, attrs, opts),
        else: plain

    children
    |> Enum.reduce(plain, fn child, plain ->
      case child do
        {:comment, _} ->
          plain

        _ ->
          _convert_node_to_plain_text(child, plain, opts)
      end
    end)
  end

  def _convert_node_to_plain_text(binary, plain, _opts) when is_binary(binary) do
    binary =
      case String.match?(plain, ~r/\n$/) do
        true ->
          binary
          |> String.trim()
          |> unescape()

        _ ->
          binary
          |> String.replace(~r/\s{2,}/, " ")
          |> String.replace(~r/(\n{2,})/, "\n")
          |> unescape()
      end

    plain <> binary
  end

  def _convert_node_to_plain_text({name, attrs, children}, plain, opts) do
    cond do
      Enum.member?(@ignore_tags, name) ->
        plain <> ""

      true ->
        plain = convert_node_to_plain_text({name, attrs, children}, plain, opts)

        plain =
          cond do
            name == "img" ->
              plain <> Fulib.get(opts, :img_replace, "[图片]")

            name == "br" ->
              String.replace(plain, @trailing_whitespace, "") <> "\n"

            name == "hr" ->
              append_block_breaks(plain) <>
                "#{
                  Fulib.String.loop_chars(
                    Fulib.get(opts, :hr_replase, "-"),
                    Fulib.get(opts, :hr_count, 31)
                  )
                }\n"

            Enum.member?(["td", "th"], name) ->
              plain <> " "

            Enum.member?(@paragraph_tags, name) ->
              append_paragraph_breaks(plain)

            Enum.member?(@block_tags, name) ->
              append_block_breaks(plain)

            true ->
              plain
          end

        plain
    end
  end

  def format_list_item(plain, attrs, opts) do
    plain =
      plain <>
        Fulib.String.loop_chars(Fulib.get(opts, :li_level_replase, "  "), attrs[:level] - 1)

    case attrs[:parent] do
      "ol" ->
        plain <> "#{attrs[:index] + 1}. "

      "ul" ->
        plain <> Fulib.get(opts, :li_trailing, "* ")
    end
  end

  # 遍历树，每遇到ul或ol，将其子节点的所有li添加深度值
  def format_list_level(children, spec \\ {0, 0, ""})

  def format_list_level([head | tail], {level, index, parent} = spec)
      when parent == "ul" or parent == "ol" do
    tail_index =
      case head do
        {head_name, _, _} ->
          if head_name == "li", do: index + 1, else: index

        {:comment, _} ->
          index
      end

    [format_list_level(head, spec) | format_list_level(tail, {level, tail_index, parent})]
  end

  def format_list_level([head | tail], spec) do
    [format_list_level(head, spec) | format_list_level(tail, spec)]
  end

  def format_list_level({name, attrs, [head | tail]}, {level, index, _parent})
      when name == "ul" or name == "ol" do
    {head_name, _, _} = head
    tail_index = if head_name == "li", do: index + 1, else: index

    children = [
      format_list_level(head, {level + 1, index, name})
      | format_list_level(tail, {level + 1, tail_index, name})
    ]

    {name, attrs, children}
  end

  def format_list_level({"li", _attrs, children}, {level, index, parent}) do
    {"li", [level: level, index: index, parent: parent],
     format_list_level(children, {level, 0, ""})}
  end

  def format_list_level({name, attrs, [head | tail]}, spec) do
    children = [format_list_level(head, spec) | format_list_level(tail, spec)]
    {name, attrs, children}
  end

  def format_list_level(child, _), do: child

  defp append_block_breaks(plain) do
    plain = String.replace(plain, @trailing_whitespace, "")
    if String.match?(plain, ~r/\n$/), do: plain, else: plain <> "\n"
  end

  defp append_paragraph_breaks(plain) do
    plain = String.replace(plain, @trailing_whitespace, "")

    if String.match?(plain, ~r/\n$/) do
      if !String.match?(plain, ~r/\n{2}$/), do: plain <> "\n", else: plain
    else
      plain <> "\n\n"
    end
  end

  def forward_to_body(binary) when is_binary(binary), do: [binary]

  def forward_to_body(children) when is_list(children), do: children

  def forward_to_body(tree) do
    _forward_to_body(tree)
  end

  defp _forward_to_body({"html", _, [head | tail]}) do
    _forward_to_body(head) || _forward_to_body(tail)
  end

  defp _forward_to_body([head | tail]) do
    _forward_to_body(head) || _forward_to_body(tail)
  end

  defp _forward_to_body([]), do: []

  defp _forward_to_body({"body", _, body}), do: body

  defp _forward_to_body({name, attrs, children}) do
    case Enum.member?(["head", "frameset"], name) do
      true ->
        nil

      _ ->
        [{name, attrs, children}]
    end
  end

  def unescape(nil), do: ""

  def unescape(text) do
    text
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
  end

  def escape(nil), do: ""

  def escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
