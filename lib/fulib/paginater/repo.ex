defmodule Fulib.Paginater.Repo do
  @doc """
  defmodule MyApp.Module do
    use Fulib.Paginater
  end

  defmodule MyApp.Module do
    use Fulib.Paginater, limit: 5
  end
  """
  defmacro __using__(opts) do
    quote do
      @scrivener_defaults unquote(opts)

      def paginate(pageable, params \\ []) do
        params =
          params
          |> Fulib.reverse_merge(@scrivener_defaults)
          |> Fulib.Paginater.Util.get_opts()

        Fulib.Paginater.paginate(pageable, __MODULE__, params)
      end
    end
  end
end
