defmodule Fulib.CacheAble do
  defmacro __using__(_opts \\ []) do
    quote do
      import Fulib.CacheAble

      @doc """
      获取cache
      """
      def fetch(cache_key, missing_fn, opts \\ []) do
        if has_key?(cache_key) do
          get(cache_key)
        else
          if is_function(missing_fn) do
            set(cache_key, missing_fn.(), opts)
          else
            set(cache_key, missing_fn, opts)
          end
        end
      end
    end
  end
end
