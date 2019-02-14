defmodule Fulib.List do
  @doc """
  将一个数组，按照每个x元素，进行分组

  # Params

  * valus 数组元素
  * number 每组的数量
  * opts
  - :fill_skip  是否跳过自动填充
  - :fill_with  用什么数据进行填充

  # Return

  返回一个二维数组
  """
  def in_groups_of(values, number, opts \\ []) do
    groups =
      values
      |> Enum.reduce([], fn value, groups ->
        {last_group, groups} = List.pop_at(groups, -1)
        last_group = last_group || []

        if length(last_group) == number do
          groups
          |> List.insert_at(-1, last_group)
          |> List.insert_at(-1, [value])
        else
          last_group = last_group |> List.insert_at(-1, value)
          groups |> List.insert_at(-1, last_group)
        end
      end)

    {last_group, groups} = List.pop_at(groups, -1)

    if last_group do
      last_group =
        if opts[:fill_skip] || length(last_group) == number do
          last_group
        else
          last_group ++ Enum.map(length(last_group)..(number - 1), fn _i -> opts[:fill_with] end)
        end

      groups |> List.insert_at(-1, last_group)
    else
      groups
    end
  end

  # list_a与list_b是否有交集
  def mixed?(list_a, list_b) do
    Enum.reduce(list_a, false, fn i, mixed ->
      mixed || Enum.member?(list_b, i)
    end)
  end

  @doc """
  转成atoms

  ## Examples

  ```
  # 一维数组只会转换一维
  Fulib.List.atoms!(["a", "fff", 1]) => [:a, :fff, :"1"]

  # 嵌套的list也会深入的转换
  Fulib.List.atoms! ["a", "fff", 1, ["a", "ff"]] => [:a, :fff, :"1", [:a, :ff]]

  # nil 依然为 nil
  Fulib.List.atoms!(nil) => nil
  
  # [] 依然为 []
  Fulib.List.atoms!([]) => []
  ```
  """
  def atoms!(nil), do: nil
  def atoms!([]), do: []

  def atoms!([item | items]) do
    [atoms!(item) | atoms!(items)]
  end

  def atoms!(item), do: Fulib.to_atom(item)

  def index_by(list, key) do
    list |> Enum.map(fn item -> {Map.get(item, key), item} end) |> Map.new()
  end

  defdelegate compact(list \\ [], opts \\ []), to: Fulib.Map, as: :compact

  def find_index(list, ele) when is_list(list) do
    Enum.find_index(list, fn x -> x == ele end) || -1
  end

  def max(nil), do: nil
  def max([]), do: nil

  def max(list) do
    Enum.max(list)
  end

  def min(nil), do: nil
  def min([]), do: nil

  def min(list) do
    Enum.min(list)
  end

  @doc """
  随机取一个或多个元素
  """
  def sample([]), do: nil
  def sample([item]), do: item

  def sample(list) do
    list |> sample(1) |> List.first()
  end

  def sample(list, count) do
    Enum.take_random(list, count)
  end

  def sort_by_values(records, values, field_key) do
    Enum.sort(records, fn a, b ->
      find_index(values, a |> Map.get(field_key)) < find_index(values, b |> Map.get(field_key))
    end)
  end

  @doc """
  获取最后一个元素
  """
  def last(list) do
    List.last(list)
  end

  @doc """
  获取最后n个元素
  """
  def last(nil, _count), do: nil
  def last([], _count), do: []
  def last(_list, 0), do: []
  def last(list, count) when count < 0, do: first(list, -count)

  def last(list, count) do
    count = min([count, length(list)])
    list |> Enum.slice(-count, count)
  end
  
  @doc """
  获取第一个元素
  """
  def first(list) do
    List.first(list)
  end

  @doc """
  获取前n个元素
  """
  def first(nil, _count), do: nil
  def first([], _count), do: []
  def first(_list, 0), do: []
  def first(list, count) when count < 0, do: last(list, -count)

  def first(list, count) do
    list |> Enum.slice(0, min([count, length(list)]))
  end
end
