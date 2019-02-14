defmodule Fulib.HTMLParse do
  @moduledoc """
  HTML的解析器
  """

  @doc """
  将数组形式的属性列表，转成Keyword形式
  """
  def parse_attrs(attrs) do
    attrs
    |> Enum.map(fn {key, value} ->
      {key |> Fulib.to_atom(), value}
    end)
    |> Keyword.new()
  end

  @doc """
  将Keyword形式的属性列表，转成List形式
  """
  def flatten_attrs(attrs) do
    attrs
    |> Enum.map(fn {key, value} ->
      {key |> Fulib.to_s(), value}
    end)
  end

  def parse(html), do: parse(html, [])

  def parse(html, _opts) when is_binary(html) do
    html_tree = html |> Floki.parse()

    cond do
      is_tuple(html_tree) or is_list(html_tree) -> html_tree
      true -> {"div", [{"html-tree", "auto"}], [html_tree]}
    end
  end

  def parse(html_tree, _opts), do: html_tree

  def ergodic_map(html_trees, collections, collect_fn)
      when is_list(html_trees) and is_function(collect_fn) do
    current_collections =
      html_trees
      |> Enum.map(fn html_tree ->
        ergodic_map(html_tree, collections, collect_fn)
      end)
      |> List.flatten()

    collections ++ current_collections
  end

  def ergodic_map(html_tree, collections, collect_fn) when is_function(collect_fn) do
    _ergodic_map(html_tree, collections, collect_fn)
  end

  defp _ergodic_map({name, attrs, rest}, collections, collect_fn)
       when is_function(collect_fn) do
    new_collections = collect_fn.({name, attrs, rest}, collections) || []

    current_collections =
      rest
      |> Enum.map(fn html_tree ->
        _ergodic_map(html_tree, collections, collect_fn)
      end)
      |> List.flatten()

    collections ++ new_collections ++ current_collections
  end

  defp _ergodic_map(other, collections, collect_fn) when is_function(collect_fn) do
    collect_fn.(other, collections) || []
  end

  # 遍历重新修改HTML结构
  def transform(html_trees, transformation) when is_list(html_trees) do
    Enum.map(html_trees, fn html_tree ->
      transform(html_tree, transformation)
    end)
  end

  def transform(html_tree, transformation) do
    _transformation(html_tree, transformation, %{ancestors: []})
  end

  defp _transformation({name, attrs, rest}, transformation, opts) do
    ancestors = opts |> Map.get(:ancestors, [])
    ancestors = List.insert_at(ancestors, -1, name)
    opts = opts |> Map.put(:ancestors, ancestors)

    {new_name, new_attrs, new_rest} = transformation.({name, attrs, rest}, opts)

    new_rest =
      Enum.map(new_rest, fn html_tree ->
        _transformation(html_tree, transformation, opts)
      end)

    {new_name, new_attrs, new_rest}
  end

  defp _transformation(other, transformation, opts) do
    transformation.(other, opts)
  end

  def raw_html(html_tree, opts \\ [])

  def raw_html({"div", [{"html-tree", "auto"}], [html_tree]}, opts) do
    raw_html(html_tree, opts)
  end

  def raw_html(html_tree, opts) do
    Floki.raw_html(html_tree, opts |> Fulib.reverse_merge(encode: false))
  end

  defdelegate map(html_tree_list, fun), to: Floki
  defdelegate attribute(html_tree, attribute_name), to: Floki
  defdelegate attribute(html, selector, attribute_name), to: Floki
  defdelegate filter_out(html_tree, selector), to: Floki
  defdelegate find(html, selector), to: Floki
  defdelegate text(html, opts \\ [deep: true, js: false, sep: ""]), to: Floki
end
