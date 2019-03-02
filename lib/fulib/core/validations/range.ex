defmodule Fulib.Validations.Range do
  def validate(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      case bounds(options) do
        {nil, nil} ->
          raise "Missing value validation range(is, min, max or range)"

        {same, same} ->
          if value == same do
            :ok
          else
            {:error, :wrong_value_range,
             Fulib.Translator.dgettext("validate", "must have a value of %{value}", value: same)}
          end

        {nil, max} ->
          if value <= max do
            :ok
          else
            {:error, :value_too_large,
             Fulib.Translator.dgettext(
               "validate",
               "must have a value of no large than %{max}",
               max: max
             )}
          end

        {min, nil} ->
          if min <= value do
            :ok
          else
            {:error, :value_too_small,
             Fulib.Translator.dgettext(
               "validate",
               "must have a value of at least %{min}",
               min: min
             )}
          end

        {min, max} ->
          if min <= value and value <= max do
            :ok
          else
            {:error, :wrong_value_range,
             Fulib.Translator.dgettext(
               "validate",
               "must have a value between %{min} and %{max}",
               min: min,
               max: max
             )}
          end
      end
    end
  end

  defp bounds(options) do
    is = Keyword.get(options, :is)
    min = Keyword.get(options, :min)
    max = Keyword.get(options, :max)
    range = Keyword.get(options, :in)

    cond do
      is -> {is, is}
      min -> {min, max}
      max -> {min, max}
      range -> {range.first, range.last}
      true -> {nil, nil}
    end
  end
end
