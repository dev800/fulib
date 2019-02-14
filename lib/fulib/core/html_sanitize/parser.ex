defmodule Fulib.HtmlSanitize.Parser do
  @doc """
  Parses a HTML string.
  ## Examples
      iex> Floki.parse("<div class=js-action>hello world</div>")
      {"div", [{"class", "js-action"}], ["hello world"]}
      iex> Floki.parse("<div>first</div><div>second</div>")
      [{"div", [], ["first"]}, {"div", [], ["second"]}]
  """

  @type html_tree :: tuple | list

  @privte_root_node "html_sanitize_dev800"

  @spec parse(binary) :: html_tree

  def parse(html) do
    html = "<#{@privte_root_node}>#{html}</#{@privte_root_node}>"
    {@privte_root_node, [], parsed} = :mochiweb_html.parse(html)

    if length(parsed) == 1, do: hd(parsed), else: parsed
  end

  def to_html(tokens) do
    {@privte_root_node, [], ensure_list(tokens)}
    |> :mochiweb_html.to_html()
    |> Enum.join()
    |> String.replace(~r/^<#{@privte_root_node}>/, "")
    |> String.replace(~r/<\/#{@privte_root_node}>$/, "")
    |> String.replace("&lt;/#{@privte_root_node}&gt;", "")
  end

  defp ensure_list(list) do
    case list do
      [_head | _tail] -> list
      _ -> [list]
    end
  end
end
