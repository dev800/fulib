defmodule Fulib.Validations.Absence do
  @moduledoc """
  必须为空的校验
  """

  def validate(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.blank?(value) do
        :ok
      else
        {:error, :not_blank, Fulib.Translator.dgettext("validate", "Not Blank")}
      end
    end
  end
end
