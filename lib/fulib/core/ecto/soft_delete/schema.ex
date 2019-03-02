defmodule Fulib.Ecto.SoftDelete.Schema do
  @moduledoc """
  Contains schema macros to add soft delete fields to a schema
  """

  @doc """
  Adds the deleted_at column to a schema
      defmodule User do
        use Ecto.Schema
        import Fulib.Ecto.SoftDelete.Schema

        schema "users" do
          field :email, :string
          soft_delete_fields()
        end
      end
  """
  defmacro soft_delete_fields do
    quote do
      field(:deleted_at, :utc_datetime)
    end
  end
end
