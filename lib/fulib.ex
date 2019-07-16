defmodule Fulib do
  @moduledoc """
  Documentation for Fulib.
  """

  def env(), do: Application.get_env(:fulib, :env, Mix.env())

  def default_currency do
    Application.get_env(:money, :default_currency, :CNY)
  end

  def each_do(item, opts \\ %{}) do
    if is_function(opts[:each_do]) do
      opts[:each_do].(item)
    end
  end

  def i18n(msgid, bindings \\ %{}) do
    Fulib.Translator.dgettext("default", msgid, bindings)
  end

  @doc """
  不让value大于max_value
  """
  def as_max(nil, _max_value), do: nil

  def as_max(value, max_value) do
    if value > max_value, do: max_value, else: value
  end

  @doc """
  不让value小于min_value
  """
  def as_min(nil, _min_value), do: nil

  def as_min(value, min_value) do
    if value < min_value, do: min_value, else: value
  end

  @doc """
  不让value小于min_value, 大于max_value
  """
  def as_range(nil, _min_value, _max_value), do: nil

  def as_range(value, min_value, max_value) do
    value |> as_min(min_value) |> as_max(max_value)
  end

  def to_list(map) when is_map(map) do
    map |> Map.to_list()
  end

  def to_list(list), do: list

  def call(q, call_fn) do
    call_fn.(q)
  end

  @doc """
  如果条件符合的时候，执行true_fn方法，否则返回自己。
  eg:
  queryable
  |> Fulib.if_call(not is_nil(params[:age]), fn queryable ->
    Ecto.Query.where(queryable, age: params[:age])
  end)
  |> Fulib.if_call(not is_nil(params[:name]), fn queryable ->
    Ecto.Query.where(queryable, name: params[:name])
  end)
  """
  def if_call(q, condition \\ true, true_fn)

  def if_call(q, condition, true_fn) do
    if condition, do: true_fn.(q), else: q
  end

  @doc """
  如果条件不符合的时候，执行false_fn方法，否则返回自己。
  eg:
  queryable
  |> Fulib.not_call(is_nil(params[:age]), fn queryable ->
    Ecto.Query.where(queryable, age: params[:age])
  end)
  |> Fulib.not_call(is_nil(params[:name]), fn queryable ->
    Ecto.Query.where(queryable, name: params[:name])
  end)
  """
  def not_call(q, condition \\ false, false_fn)

  def not_call(q, condition, false_fn) do
    if condition, do: q, else: false_fn.(q)
  end

  defmacro cond_pipe(q, do: block) do
    # get the statements' asts from the do block
    asts =
      block
      |> case do
        # if the do block has multiple statements it will be a __block__
        # and the statements' asts will be its args
        {:__block__, _, args} ->
          args

        # if only one statement in the do block the value of the :do:
        # key will be the statement's ast
        ast ->
          [ast]
      end

    asts
    |> Enum.reduce(
      q,
      fn {condition, true_fn}, acc ->
        quote do
          if unquote(condition) do
            apply(unquote(true_fn), [unquote(acc)])
          else
            unquote(acc)
          end
        end
      end
    )
  end

  defdelegate naive_now(), to: Fulib.DateTime

  defdelegate in_groups_of(list, key, opts \\ []), to: Fulib.List
  defdelegate index_by(list, key), to: Fulib.List
  defdelegate get_index(list, ele), to: Fulib.List, as: :find_index

  defdelegate to_json(term, options \\ []), to: Jason, as: :encode!
  def from_json(term, options \\ [])
  def from_json(nil, _options), do: nil
  defdelegate from_json(term, options), to: Jason, as: :decode!

  defdelegate to_yaml(term, opts \\ []), to: Fulib.String.Yaml, as: :encode!
  defdelegate from_yaml(term, opts \\ []), to: Fulib.String.Yaml, as: :decode!

  def get(map_or_list, key, default \\ nil, when_nil \\ nil)

  def get(map_or_list, key, default, when_nil) do
    _get(map_or_list, key, default, when_nil)
  end

  def get_or(map_or_list, keys, default \\ nil, when_nil \\ nil)

  def get_or(map_or_list, keys, default, when_nil) do
    _get_or(map_or_list, keys, default, when_nil)
  end

  defp _get_or(map_or_list, [key], default, when_nil) do
    _get(map_or_list, key, default, when_nil)
  end

  defp _get_or(map_or_list, [key | keys], default, when_nil) do
    map_or_list
    |> get(key)
    |> if_call(fn value ->
      if is_nil(value) do
        _get_or(map_or_list, keys, default, when_nil)
      else
        value
      end
    end)
  end

  defp _get_or(map_or_list, key, default, when_nil) do
    _get(map_or_list, key, default, when_nil)
  end

  defp _get(map, key, default, when_nil) when is_map(map) do
    map
    |> Map.get(key, default)
    |> case do
      nil -> when_nil
      value -> value
    end
  end

  defp _get(list, key, default, when_nil) when is_list(list) do
    list
    |> Keyword.get(key, default)
    |> case do
      nil -> when_nil
      value -> value
    end
  end

  defp _get(_, _key, nil, when_nil), do: when_nil

  defp _get(_, _key, default, _when_nil), do: default

  def get_in(data, keys, when_nil) do
    value = get_in(data, keys)
    if is_nil(value), do: when_nil, else: value
  end

  def put(map, key, value) when is_map(map), do: Map.put(map, key, value)
  def put(list, key, value) when is_list(list), do: Keyword.put(list, key, value)
  def put(other, _key, _value), do: other

  def drop(map, keys) when is_map(map), do: Map.drop(map, keys)
  def drop(list, keys) when is_list(list), do: Keyword.drop(list, keys)
  def drop(other, _keys), do: other

  def to_array(nil), do: []
  def to_array([]), do: []
  def to_array([_a | _] = array), do: array
  def to_array(item), do: [item]

  def reverse(map) when is_map(map), do: Fulib.Map.reverse(map)
  def reverse(string) when is_bitstring(string), do: String.reverse(string)
  def reverse(enumerable), do: Enum.reverse(enumerable)

  #### Begin Core #############################
  defdelegate validate(value, value_type, rules \\ %{}), to: Fulib.Validate, as: :validate_value

  defdelegate singularize(word), to: Fulib.String.Pluralize, as: :singularize
  defdelegate pluralize(word), to: Fulib.String.Pluralize, as: :pluralize
  defdelegate inflect(word, n), to: Fulib.String.Pluralize, as: :inflect

  defdelegate blank?(value), to: Fulib.String, as: :blank?
  defdelegate present?(value), to: Fulib.String, as: :present?

  defdelegate hmac_sha256(value), to: Fulib.String, as: :hmac_sha256
  defdelegate hmac_sha256(secret, value), to: Fulib.String, as: :hmac_sha256
  defdelegate hmac_sha512(value), to: Fulib.String, as: :hmac_sha512
  defdelegate hmac_sha512(secret, value), to: Fulib.String, as: :hmac_sha512

  defdelegate sha512(value), to: Fulib.String, as: :sha512
  defdelegate sha256(value), to: Fulib.String, as: :sha256
  defdelegate md5(value), to: Fulib.String, as: :md5

  defdelegate to_s(value), to: Fulib.String, as: :parse
  defdelegate to_atom(value), to: Fulib.Atom, as: :parse
  defdelegate to_i(value), to: Fulib.Integer, as: :parse
  defdelegate to_f(value), to: Fulib.Float, as: :parse
  defdelegate to_boolean(value), to: Fulib.Boolean, as: :parse
  defdelegate to_enum_map(value), to: Fulib.Map, as: :to_enum_map

  defdelegate html_escape(value), to: Fulib.String.HTMLFormat, as: :escape
  defdelegate html_unescape(value), to: Fulib.String.HTMLFormat, as: :unescape

  #### Begin Logger ############################
  defdelegate log(info \\ nil, opts \\ []), to: Fulib.Logger
  defdelegate log_debug(info \\ nil, opts \\ []), to: Fulib.Logger
  defdelegate log_info(info \\ nil, opts \\ []), to: Fulib.Logger
  defdelegate log_warn(info \\ nil, opts \\ []), to: Fulib.Logger
  defdelegate log_error(info \\ nil, opts \\ []), to: Fulib.Logger
  defdelegate log_inspect(info \\ nil, opts \\ []), to: Fulib.Logger
  defdelegate log_exception(exception \\ nil, opts \\ []), to: Fulib.Logger
  defdelegate log_stacktrace(), to: Fulib.Logger

  def rescue_exception(e) do
    e |> log_exception
    {:error, e |> Exception.message()}
  end

  def bench_log(call_fn) when is_function(call_fn) do
    bench_log([], call_fn)
  end

  def bench_log(args, call_fn) when is_function(call_fn) do
    start_at = Timex.now()
    call_result = call_fn.()
    Fulib.log_info(args ++ [" with: #{Timex.diff(Timex.now(), start_at) / 1000}ms"])
    call_result
  end

  def has_key?(map, key) when is_map(map), do: Map.has_key?(map, key)
  def has_key?(keywords, key) when is_list(keywords), do: Keyword.has_key?(keywords, key)

  def keys(map) when is_map(map), do: Map.keys(map)
  def keys(keywords) when is_list(keywords), do: Keyword.keys(keywords)
  def keys(_), do: nil

  def take(map, keys) when is_map(map), do: Map.take(map, keys)
  def take(keywords, keys) when is_list(keywords), do: Keyword.take(keywords, keys)
  def take(other, _keys), do: other

  #### Begin List #############################
  defdelegate sample(list), to: Fulib.List, as: :sample
  defdelegate sample(list, count), to: Fulib.List, as: :sample
  defdelegate compact(list \\ [], opts \\ []), to: Fulib.Map, as: :compact

  def merge(original, initial) when is_map(original) and is_map(initial) do
    Map.merge(original, initial)
  end

  def merge(original, initial) when is_list(original) and is_list(initial) do
    Keyword.merge(original, initial)
  end

  def merge(original, initial) when is_map(original) and is_list(initial) do
    Map.merge(original, Map.new(initial))
  end

  def merge(original, initial) when is_list(original) and is_map(initial) do
    Keyword.merge(original, Map.to_list(initial))
  end

  def reverse_merge(original, initial) when is_map(original) and is_map(initial) do
    Map.merge(initial, original)
  end

  def reverse_merge(original, initial) when is_list(original) and is_list(initial) do
    Keyword.merge(initial, original)
  end

  def reverse_merge(original, initial) when is_map(original) and is_list(initial) do
    Map.merge(Map.new(initial), original)
  end

  def reverse_merge(original, initial) when is_list(original) and is_map(initial) do
    Keyword.merge(Map.to_list(initial), original)
  end

  #### Begin Map #############################
  def atom_keys!(map) when is_map(map) do
    Fulib.Map.atom_keys!(map)
  end

  def atom_keys!(keywords) when is_list(keywords), do: keywords
  def atom_keys!(params), do: params

  def atom_keys_deep!(map) when is_map(map) do
    Fulib.Map.atom_keys_deep!(map)
  end

  def atom_keys_deep!(keywords) when is_list(keywords), do: keywords
  def atom_keys_deep!(params), do: params

  def string_keys!(map) when is_map(map) do
    Fulib.Map.string_keys!(map)
  end

  def string_keys!(keywords) when is_list(keywords), do: keywords
  def string_keys!(params), do: params

  def string_keys_deep!(map) when is_map(map) do
    Fulib.Map.string_keys_deep!(map)
  end

  def string_keys_deep!(keywords) when is_list(keywords), do: keywords
  def string_keys_deep!(params), do: params

  def is_struct(%{__struct__: _}), do: true
  def is_struct(_), do: false

  def handle_empty(value, fill \\ "-"), do: if(value |> Fulib.present?(), do: value, else: fill)
  def if_present(value, func), do: if(value |> Fulib.present?(), do: func.(value), else: value)

  defdelegate pmap(collection, func, timeout \\ 5000), to: Fulib.Async, as: :pmap
end
