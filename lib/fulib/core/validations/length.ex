defmodule Fulib.Validations.Length do
  def validate(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      chars = Fulib.get(options, :chars, false, false) |> Fulib.to_boolean()
      trim = Fulib.get(options, :trim, false, false) |> Fulib.to_boolean()

      size =
        if chars do
          Fulib.String.chars_length(value, trim: trim)
        else
          Fulib.String.length(value, trim: trim)
        end

      case bounds(options) do
        {nil, nil} ->
          raise "Missing length validation range(is, min, max or range)"

        {same, same} ->
          if size == same do
            :ok
          else
            message =
              if chars do
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length of %{length} or %{length_chars}",
                  length_chars: (same / 2) |> Fulib.to_i(),
                  length: same
                )
              else
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length of %{length}",
                  length: same
                )
              end

            {:error, :wrong_length, message}
          end

        {nil, max} ->
          if size <= max do
            :ok
          else
            message =
              if chars do
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length of no more than %{max} or %{max_chars}",
                  max_chars: (max / 2) |> Fulib.to_i(),
                  max: max
                )
              else
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length of no more than %{max}",
                  max: max
                )
              end

            {:error, :too_long, message}
          end

        {min, nil} ->
          if min <= size do
            :ok
          else
            message =
              if chars do
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length of at least %{min} or %{min_chars}",
                  min_chars: (min / 2) |> Fulib.to_i(),
                  min: min
                )
              else
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length of at least %{min}",
                  min: min
                )
              end

            {:error, :too_short, message}
          end

        {min, max} ->
          if min <= size and size <= max do
            :ok
          else
            message =
              if chars do
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length between %{min} or %{min_chars} and %{min_chars} or %{max_chars}",
                  min_chars: (min / 2) |> Fulib.to_i(),
                  max_chars: (max / 2) |> Fulib.to_i(),
                  min: min,
                  max: max
                )
              else
                Fulib.Translator.dgettext(
                  "validate",
                  "must have a length between %{min} and %{max}",
                  min: min,
                  max: max
                )
              end

            {:error, :wrong_length, message}
          end
      end
    end
  end

  defp bounds(options) do
    is = Fulib.get(options, :is)
    min = Fulib.get(options, :min)
    max = Fulib.get(options, :max)
    range = Fulib.get(options, :in)

    cond do
      is -> {is, is}
      min -> {min, max}
      max -> {min, max}
      range -> {range.first, range.last}
      true -> {nil, nil}
    end
  end
end
