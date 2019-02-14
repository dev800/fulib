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
end
