defmodule Fulib.Validations.Numericality do
  def validate(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      str = String.to_charlist("#{value}")

      valid_result =
        case :string.to_integer(str) do
          {:error, :no_integer} ->
            :number_expected

          {_value, []} ->
            :ok

          {_value, _} ->
            case :string.to_float(str) do
              {:error, _} -> :rest_not_allowed
              {_value_f, []} -> :ok
              {_value_f, _} -> :rest_not_allowed
            end
        end

      case valid_result do
        :ok -> :ok
        _ -> {:error, :not_number, Fulib.Translator.dgettext("validate", "Must be a number")}
      end
    end
  end
end
