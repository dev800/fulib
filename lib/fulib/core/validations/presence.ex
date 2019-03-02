defmodule Fulib.Validations.Presence do
  @moduledoc """
  必须不能为空的校验
  """
  def validate(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.blank?(value) do
        {:error, :not_present, Fulib.Translator.dgettext("validate", "Not Present")}
      else
        :ok
      end
    end
  end
end
