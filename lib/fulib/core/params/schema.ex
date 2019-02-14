defmodule Fulib.Params.Schema do
  @doc false
  defmacro __using__([]) do
    quote do
      import Fulib.Params.Schema, only: [schema: 1]
      unquote(__use__(:ecto))
      unquote(__use__(:params))
    end
  end

  @doc false
  defmacro __using__(schema) do
    quote bind_quoted: [schema: schema] do
      import Fulib.Params.Def, only: [defschema: 1]
      Fulib.Params.Def.defschema(schema)
    end
  end

  @doc false
  defmacro schema(do: definition) do
    quote do
      Ecto.Schema.schema "params #{__MODULE__}" do
        unquote(definition)
      end
    end
  end

  defp __use__(:ecto) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @primary_key {:_id, :binary_id, autogenerate: false}
    end
  end

  defp __use__(:params) do
    quote do
      Module.register_attribute(__MODULE__, :required, persist: true)
      Module.register_attribute(__MODULE__, :optional, persist: true)
      Module.register_attribute(__MODULE__, :schema, persist: true)

      @behaviour Fulib.Params.Behaviour

      def from(params, options \\ []) when is_list(options) do
        on_cast = Keyword.get(options, :with, &__MODULE__.changeset(&1, &2))
        __MODULE__ |> struct |> Ecto.Changeset.change() |> on_cast.(params)
      end

      def data(params, options \\ []) when is_list(options) do
        case from(params, options) do
          changeset = %{valid?: true} -> {:ok, Fulib.Params.data(changeset)}
          changeset -> {:error, changeset}
        end
      end

      def changeset(changeset, params) do
        Fulib.Params.changeset(changeset, params)
      end

      defoverridable changeset: 2
    end
  end
end
