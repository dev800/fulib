defmodule Fulib.LevelCache do
  import ShorterMaps
  alias Fulib.GlobalCache

  @missing_value :_____missing_____

  defp _get(key, default \\ nil) do
    key
    |> process_get()
    |> case do
      nil ->
        key
        |> global_cache_key()
        |> GlobalCache.get()
        |> case do
          nil ->
            {:ok, :missing, default}

          value ->
            {:ok, :global_hit, value}
        end

      value ->
        {:ok, :process_hit, value}
    end
  end

  @doc """
  先在Process里检索，然后去Fulib.GlobalCache去检索
  """
  def get(key, default \\ nil) do
    key
    |> _get(default)
    |> case do
      {:ok, _, @missing_value} ->
        default

      {:ok, _, value} ->
        value
    end
  end

  defp _get_many(keys) do
    keys = keys |> Fulib.to_array()

    {process_hits, global_hits} =
      keys
      |> Enum.reduce({%{}, %{}}, fn key, {process_hits, global_hits} ->
        key
        |> _get()
        |> case do
          {:ok, :missing, _default} ->
            {process_hits, global_hits}

          {:ok, :global_hit, hit} ->
            {process_hits, global_hits |> Map.put(key, hit)}

          {:ok, _, hit} ->
            {process_hits |> Map.put(key, hit), global_hits}
        end
      end)

    missing_keys =
      keys
      |> Kernel.--(Map.keys(process_hits))
      |> Kernel.--(Map.keys(global_hits))

    missing_cache_keys_index =
      missing_keys
      |> Enum.reduce(%{}, fn key, pairs ->
        pairs |> Map.put(global_cache_key(key), key)
      end)

    global_hits =
      missing_cache_keys_index
      |> Map.keys()
      |> GlobalCache.get_many()
      |> Enum.reduce(global_hits, fn {cache_key, value}, global_hits ->
        missing_cache_keys_index
        |> Fulib.get(cache_key)
        |> case do
          nil ->
            global_hits

          key ->
            global_hits |> Map.put(key, value)
        end
      end)

    ~M(process_hits, global_hits)
  end

  def get_many(keys) do
    keys
    |> _get_many()
    |> case do
      ~M(process_hits, global_hits) ->
        process_hits |> _clean_missing() |> Map.merge(_clean_missing(global_hits))

      _ ->
        %{}
    end
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
    global_cache_delete(key)
  end

  def global_cache_delete(key) do
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
        key |> global_cache_delete()

      value ->
        key
        |> global_cache_key()
        |> GlobalCache.set(value)
    end

    value
  end

  def fetch_many(keys, missing_fn) do
    keys = keys |> Fulib.to_array()
    ~M(process_hits, global_hits) = keys |> _get_many()

    missing_keys =
      keys
      |> Kernel.--(Map.keys(process_hits))
      |> Kernel.--(Map.keys(global_hits))

    missings_index =
      missing_keys
      |> missing_fn.()
      |> Kernel.||(%{})
      |> Map.take(missing_keys)

    Enum.each(global_hits, fn {key, value} ->
      process_put(key, value)
    end)

    Enum.each(missing_keys, fn key ->
      put(key, Fulib.get(missings_index, key))
    end)

    process_hits
    |> Map.merge(missings_index)
    |> _clean_missing()
    |> Map.merge(_clean_missing(global_hits))
  end

  def fetch(key, missing_fn) do
    key
    |> _get()
    |> case do
      {:ok, :missing, _default} ->
        put(key, missing_fn.())

      {:ok, :global_hit, value} ->
        process_put(key, value)
        value

      {:ok, _, value} ->
        value
    end
    |> case do
      @missing_value ->
        nil

      value ->
        value
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
    key |> process_cache_key()

    if is_nil(value) do
      key |> Process.delete()
    else
      key |> Process.put(value)
    end

    value
  end

  def process_fetch(key, missing_fn) do
    key
    |> process_get()
    |> case do
      nil ->
        process_put(key, missing_fn.())

      other ->
        other
    end
  end

  def process_cache_key(key), do: "Fulib.LV_PCK:#{key}"

  def global_cache_key(key), do: "Fulib.LV_GCK:#{key}"
end
