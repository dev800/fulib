defmodule Fulib.Validations.Acceptance do
  def must(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.to_boolean(value) == true do
        :ok
      else
        {:error, :must_acceptance, Fulib.Translator.dgettext("validate", "must acceptance")}
      end
    end
  end

  def cannot(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.to_boolean(value) == false do
        :ok
      else
        {:error, :cannot_acceptance, Fulib.Translator.dgettext("validate", "cannot acceptance")}
      end
    end
  end
end
