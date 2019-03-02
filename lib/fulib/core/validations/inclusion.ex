defmodule Fulib.Validations.Inclusion do
  def validate(value, options) when is_list(options) do
    Fulib.Validate.unless_skipping value, options do
      if Keyword.keyword?(options) do
        list = Keyword.get(options, :in, [])
        check_type = Keyword.get(options, :check_type, :radio)
        message = Keyword.get(options, :message)

        case check_type do
          :multiple ->
            values =
              cond do
                is_nil(value) -> []
                is_list(value) -> value
                true -> [value]
              end

            cond do
              not is_list(values) ->
                {:error, :not_inclusion,
                 message ||
                   Fulib.Translator.dgettext("validate", "must be a list", values: values)}

              Enum.empty?(values) ->
                {
                  :error,
                  :not_inclusion,
                  message ||
                    Fulib.Translator.dgettext(
                      "validate",
                      "must be items of %{list}",
                      list: inspect(list),
                      values: values
                    )
                }

              Enum.any?(invalid_values = values -- list) ->
                {
                  :error,
                  :not_inclusion,
                  message ||
                    Fulib.Translator.dgettext(
                      "validate",
                      "you put invalid not inclusion values: %{invalid_values}",
                      invalid_values: inspect(invalid_values)
                    )
                }

              true ->
                :ok
            end

          _ ->
            if Enum.any?(list) && Enum.member?(list, value) do
              :ok
            else
              {:error, :not_inclusion,
               message ||
                 Fulib.Translator.dgettext(
                   "validate",
                   "must be one of %{list}",
                   list: inspect(list),
                   value: value
                 )}
            end
        end
      else
        validate(value, in: options)
      end
    end
  end
end
