defmodule Fulib.Map do
  @moduledoc """
  自定义，扩展Map的一些方法
  """

  def recase_keys!(map, opts \\ [])

  def recase_keys!([item | array], opts) do
    [recase_keys_deep!(item, opts)] ++ recase_keys_deep!(array, opts)
  end

  def recase_keys!(map, opts) when is_map(map) do
    if require_enumer?(map) do
      map
      |> Enum.map(fn {key, value} ->
        {_recase(key, opts), value}
      end)
      |> Map.new()
    else
      map
    end
  end

  def recase_keys!(value, _opts), do: value

  def recase_keys_deep!([item | array], opts) do
    [recase_keys_deep!(item, opts)] ++ recase_keys_deep!(array, opts)
  end

  def recase_keys_deep!(map, opts) when is_map(map) do
    if require_enumer?(map) do
      map
      |> Enum.map(fn {key, value} ->
        if require_enumer?(value) do
          {_recase(key, opts), value |> recase_keys_deep!(opts)}
        else
          {_recase(key, opts), value}
        end
      end)
      |> Map.new()
    else
      map
    end
  end

  def recase_keys_deep!(value, _opts), do: value

  defp _recase(key, opts) when is_atom(key) do
    key |> Fulib.to_s() |> _recase(opts) |> Fulib.to_atom()
  end

  defp _recase(key, opts) when is_binary(key) do
    Fulib.String.recase(key, opts[:case])
  end

  defp _recase(key, _opts), do: key

  def to_enum_map(keyword) when is_list(keyword) do
    if Keyword.keyword?(keyword) do
      Map.new(keyword)
    else
      %{}
    end
  end

  def to_enum_map(map) when is_map(map) do
    if Fulib.get(map, :__struct__, nil, nil) do
      Map.from_struct(map)
    else
      map
    end
  end

  def parse(_), do: %{}

  def atom_keys!([item | array]) do
    [atom_keys!(item)] ++ atom_keys!(array)
  end

  def atom_keys!(params) when is_map(params) do
    if require_enumer?(params) do
      params
      |> Enum.map(fn {key, value} ->
        {key |> Fulib.to_atom(), value}
      end)
      |> Map.new()
    else
      params
    end
  end

  def atom_keys!(value), do: value

  def atom_keys_deep!([item | array]) do
    [atom_keys_deep!(item)] ++ atom_keys_deep!(array)
  end

  def atom_keys_deep!(params) when is_map(params) do
    if require_enumer?(params) do
      params
      |> Enum.map(fn {key, value} ->
        if require_enumer?(value) do
          {key |> Fulib.to_atom(), value |> atom_keys_deep!}
        else
          {key |> Fulib.to_atom(), value}
        end
      end)
      |> Map.new()
    else
      params
    end
  end

  def atom_keys_deep!(value), do: value

  def string_keys!([item | array]) do
    [string_keys!(item)] ++ string_keys!(array)
  end

  def string_keys!(params) when is_map(params) do
    if require_enumer?(params) do
      params
      |> Enum.map(fn {key, value} ->
        {key |> Fulib.to_s(), value}
      end)
      |> Map.new()
    else
      params
    end
  end

  def string_keys!(value), do: value

  def string_keys_deep!([item | array]) do
    [string_keys_deep!(item)] ++ string_keys_deep!(array)
  end

  def string_keys_deep!(params) when is_map(params) do
    if require_enumer?(params) do
      params
      |> Enum.map(fn {key, value} ->
        if require_enumer?(value) do
          {key |> Fulib.to_s(), value |> string_keys_deep!}
        else
          {key |> Fulib.to_s(), value}
        end
      end)
      |> Map.new()
    else
      params
    end
  end

  def string_keys_deep!(value), do: value

  @doc """
  过滤掉为false，nil的值

  ## opts

  * `filter_presence` 表示要根据是否为空过滤，true/false 默认为false
  * `filter_false` 表示要根据是否为false过滤，true/false 默认为false
  """
  def compact(map, opts \\ [])

  def compact(list, opts) when is_list(list) do
    if require_enumer?(list) do
      list |> _compact(opts)
    else
      list
    end
  end

  def compact(map, opts) when is_map(map) do
    if require_enumer?(map) do
      map |> _compact(opts) |> Map.new()
    else
      map
    end
  end

  defp _compact(map, opts) do
    filter_presence = opts |> Fulib.get_or([:filter_presence], false)
    filter_false = opts |> Fulib.get_or([:filter_false], false)

    map
    |> Enum.filter(fn item ->
      item
      |> case do
        {_k, v} ->
          v

        v ->
          v
      end
      |> _compact_filter?(filter_presence, filter_false)
    end)
  end

  defp _compact_filter?(item, filter_presence, filter_false) do
    cond do
      filter_presence && filter_false ->
        not is_nil(item) && item != false && Fulib.present?(item)

      not filter_presence && filter_false ->
        not is_nil(item) && item != false

      filter_presence && not filter_false ->
        not is_nil(item) && Fulib.present?(item)

      true ->
        not is_nil(item)
    end
  end

  def reverse(map) when is_map(map) do
    if require_enumer?(map) do
      map
      |> Enum.map(fn {k, v} -> {v, k} end)
      |> Map.new()
    else
      map
    end
  end

  def diff(map_old, map_new, cast_fields \\ []) do
    cast_fields =
      cast_fields
      |> Enum.map(fn f ->
        case f do
          {k, type} -> {k, type}
          _ -> {f, :object}
        end
      end)
      |> Map.new()

    (map_new || %{})
    |> Map.take(cast_fields |> Map.keys())
    |> Enum.reject(fn {k, v} -> v == Fulib.get(map_old, k) end)
    |> Map.new()
    |> Map.keys()
    |> Enum.map(fn key ->
      old_value = Fulib.get(map_old, key)
      new_value = Fulib.get(map_new, key)

      case cast_fields[key] do
        :map ->
          {
            key,
            diff(
              old_value,
              new_value,
              (new_value || %{}) |> Map.keys()
            )
          }

        _ ->
          {key, [old_value, new_value]}
      end
    end)
    |> Map.new()
  end

  def require_enumer?(%{__struct__: _}), do: false

  def require_enumer?(data) do
    !!Enumerable.impl_for(data)
  end
end
