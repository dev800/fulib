defmodule Fulib.LevelCache do
  alias Fulib.GlobalCache

  @missing_value :_____missing_____

  def _get(key, default \\ nil) do
    key
    |> process_get()
    |> case do
      nil ->
        key
        |> global_cache_key()
        |> GlobalCache.get()
        |> case do
          nil ->
            default

          other ->
            other
        end

      other ->
        other
    end
  end

  @doc """
  先在Process里检索，然后去Fulib.GlobalCache去检索
  """
  def get(key, default \\ nil) do
    key
    |> _get(default)
    |> case do
      @missing_value ->
        default

      other ->
        other
    end
  end

  defp _get_many(keys) do
    keys = keys |> Fulib.to_array()

    hits =
      keys
      |> Enum.reduce(%{}, fn key, hits ->
        key
        |> _get()
        |> case do
          nil ->
            hits

          hit ->
            hits |> Map.put(key, hit)
        end
      end)

    missing_keys = keys |> Kernel.--(Map.keys(hits))

    missing_cache_keys_index =
      missing_keys
      |> Enum.reduce(%{}, fn key, pairs ->
        pairs |> Map.put(global_cache_key(key), key)
      end)

    missing_cache_keys_index
    |> Map.keys()
    |> GlobalCache.get_many()
    |> Enum.reduce(hits, fn {cache_key, value}, hits ->
      missing_cache_keys_index
      |> Fulib.get(cache_key)
      |> case do
        nil ->
          hits

        key ->
          hits |> Map.put(key, value)
      end
    end)
  end

  def get_many(keys) do
    keys
    |> _get_many()
    |> _clean_missing()
  end

  defp _clean_missing(pairs) do
    pairs
    |> Enum.reduce(%{}, fn {key, value}, pairs ->
      case value do
        @missing_value ->
          pairs

        value ->
          pairs |> Map.put(key, value)
      end
    end)
  end

  def delete(key) do
    process_delete(key)
    _global_cache_delete(key)
  end

  defp _global_cache_delete(key) do
    key
    |> global_cache_key()
    |> GlobalCache.set(@missing_value, ttl: 3600)

    nil
  end

  @doc """
  先更新Process里检索，然后更新Fulib.GlobalCache检索
  """
  def put(key, value) do
    process_put(key, value)

    case value do
      nil ->
        key |> _global_cache_delete()

      value ->
        GlobalCache.set(global_cache_key(key), value)
    end

    value
  end

  def fetch_many(keys, missing_fn) do
    keys = keys |> Fulib.to_array()
    hits = _get_many(keys)
    missing_keys = keys |> Kernel.--(Map.keys(hits))

    missings_index =
      missing_keys
      |> missing_fn.()
      |> Kernel.||(%{})
      |> Map.take(missing_keys)

    Enum.each(missing_keys, fn key ->
      put(key, Fulib.get(missings_index, key))
    end)

    hits
    |> Map.merge(missings_index)
    |> _clean_missing()
  end

  def fetch(key, missing_fn) do
    key
    |> _get()
    |> case do
      nil ->
        put(key, missing_fn.())

      other ->
        other
    end
    |> case do
      @missing_value ->
        nil

      other ->
        other
    end
  end

  def process_delete(key) do
    key
    |> process_cache_key()
    |> Process.delete()

    nil
  end

  def process_get(key) do
    key
    |> process_cache_key()
    |> Process.get()
  end

  def process_put(key, value) do
    key
    |> process_cache_key()
    |> Process.put(value)

    value
  end

  def process_fetch(key, process_fn) do
    key
    |> process_get()
    |> case do
      nil ->
        process_put(key, process_fn.())

      other ->
        other
    end
  end

  def process_cache_key(key), do: "LV_PD:#{key}"

  def global_cache_key(key), do: "LV_GL:#{key}"
end
