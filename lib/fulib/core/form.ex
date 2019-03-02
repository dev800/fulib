defmodule Fulib.Form do
  defstruct valid?: true,
            changeset: %Ecto.Changeset{},
            entries: %{},
            origin: nil,
            module: nil,
            human: nil,
            human_fields: %{},
            human_errors: [],
            errors: []

  def put_entries(changeset, entries \\ []) do
    entries = entries |> Map.new()

    entries =
      changeset
      |> Fulib.get(:entries, %{})
      |> Fulib.merge(entries)

    changeset |> Fulib.put(:entries, entries)
  end

  def put_entry(changeset, field, value) do
    entries =
      changeset
      |> Fulib.get(:entries, %{})
      |> Fulib.put(field, value)

    changeset |> Fulib.put(:entries, entries)
  end

  def get_entry(changeset, field, default_value \\ nil, when_nil \\ nil) do
    changeset
    |> Fulib.get(:entries, %{})
    |> Fulib.get(field, default_value, when_nil)
  end

  def get_entries(changeset, fields) do
    fields
    |> Fulib.to_array()
    |> Enum.reduce(%{}, fn x, acc ->
      case x do
        {field, default} ->
          Map.put(acc, field, get_entry(changeset, field, default, default))

        field ->
          Map.put(acc, field, get_entry(changeset, field))
      end
    end)
  end

  def get_param(changeset, field, default \\ nil) do
    Ecto.Changeset.get_change(changeset, field, Fulib.get(changeset.data, field, default))
  end

  def get_params(changeset, fields, opts \\ []) do
    fields
    |> Fulib.to_array()
    |> Enum.reduce(%{}, fn x, acc ->
      case x do
        {field, default} ->
          Map.put(acc, field, get_param(changeset, field, default))

        field ->
          Map.put(acc, field, get_param(changeset, field))
      end
    end)
    |> Fulib.if_call(Fulib.get(opts, :compact, true), fn changes ->
      changes |> Fulib.Map.compact(opts)
    end)
  end

  @doc """
  ## opts

  ` `:compact` true[true]/false 是否将非空字段过滤掉
  * `:filter_false` true/false[默认] 是否过滤掉false值
  * `:filter_presence` true/false[默认] 是否过滤空字符串
  """
  def get_changes(changeset, fields, opts \\ []) do
    fields
    |> Fulib.to_array()
    |> Enum.reduce(%{}, fn x, acc ->
      case x do
        {field, default} ->
          Map.put(acc, field, Ecto.Changeset.get_change(changeset, field, default))

        field ->
          Map.put(acc, field, Ecto.Changeset.get_change(changeset, field))
      end
    end)
    |> Fulib.if_call(Fulib.get(opts, :compact, true), fn changes ->
      changes |> Fulib.Map.compact(opts)
    end)
  end
end
