defmodule Fulib.Ecto.QueryExtends do
  @moduledoc """
  Ecto的query扩展
  """

  @doc """
  空值：排序在后面
  ## Thanks
  ```
  * https://github.com/elixir-ecto/ecto/issues/1475
  ```
  """
  defmacro nulls_last(field) do
    quote do
      fragment("? NULLS LAST", unquote(field))
    end
  end
  defmacro nulls_last(field, :desc) do
    quote do
      fragment("? DESC NULLS LAST", unquote(field))
    end
  end
  defmacro nulls_last(field, :asc) do
    quote do
      fragment("? NULLS LAST", unquote(field))
    end
  end

  @doc """
  空值：排序在前面
  """
  defmacro nulls_first(field) do
    quote do
      fragment("? NULLS FIRST", unquote(field))
    end
  end
  defmacro nulls_first(field, :desc) do
    quote do
      fragment("? DESC NULLS FIRST", unquote(field))
    end
  end
  defmacro nulls_first(field, :asc) do
    quote do
      fragment("? NULLS FIRST", unquote(field))
    end
  end
end
