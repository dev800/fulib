defmodule Fulib.Validate do
  @available_rule_keys [
    :presence,
    :blank,
    :min_length,
    :max_length,
    :min_value,
    :max_value,
    :numericality,
    :format_with,
    :format_message,
    :format_email,
    :format_url,
    :format_integer,
    :format_pure_number,
    :inclusion,
    :exclusion,
    :acceptance,
    :trim,
    :chars
  ]

  def unless_skipping(value, options, do: unskipped) do
    if skip?(value, options) do
      :ok
    else
      unskipped
    end
  end

  def skip?(value, options) do
    cond do
      Fulib.get(options, :allow_blank, false) -> Fulib.blank?(value)
      Fulib.get(options, :allow_nil, false) -> value == nil
      true -> false
    end
  end

  def validate_changeset(%Ecto.Changeset{} = changeset, rules \\ %{}) do
    if Fulib.blank?(rules) do
      changeset
    else
      schema_def = changeset.data.__struct__.__schema__(:dump)

      changeset
      |> Fulib.Form.get_params(schema_def |> Map.keys())
      |> Enum.reduce(changeset, fn {field, value}, changeset ->
        schema_def
        |> Fulib.get(field)
        |> case do
          {_field, value_type} ->
            value
            |> validate_value(value_type, rules |> Fulib.get(field, %{}))
            |> Enum.reduce(changeset, fn validate, changeset ->
              case validate do
                {:error, reason, message} ->
                  Ecto.Changeset.add_error(changeset, field, message, validation: reason)

                _ ->
                  changeset
              end
            end)

          _ ->
            changeset
        end
      end)
    end
  end

  @doc """
  校验数据值

  ## Params

  ### value

  ### value_type

  数据类型: :integer, :string, :boolean, :float, :utc_datetime, and {:array,  :xxx}

  ### rules

  * `:presence`
  * `:blank`
  * `:min_length`
  * `:max_length`
  * `:min_value`
  * `:max_value`
  * `:numericality`
  * `:format_with`
  * `:format_message`
  * `:format_email`
  * `:format_url`
  * `:format_integer`
  * `:format_pure_number`
  * `:inclusion`
  * `:exclusion`
  * `:acceptance`
  * `:trim`
  * `:chars`
  """
  def validate_value(value, value_type, rules \\ %{}) do
    if Fulib.blank?(rules) do
      []
    else
      options =
        rules
        |> Fulib.take([:allow_blank, :allow_nil, :check_type])
        |> Fulib.to_list()

      current_value = Fulib.Value.convert_to(value, value_type)

      rules
      |> _normalize_rules!
      |> Enum.map(fn {key, rule} ->
        unless_skipping(current_value, options) do
          _validate_value(current_value, key, rule, rules, options)
        end
      end)
      |> Enum.filter(fn validate ->
        case validate do
          :ok -> false
          _ -> true
        end
      end)
    end
  end

  defp _normalize_rules!(rules) do
    rules = rules |> Fulib.take(@available_rule_keys)
    trim = rules |> Fulib.get(:trim, true) |> Fulib.to_boolean()
    chars = rules |> Fulib.get(:chars, true) |> Fulib.to_boolean()

    rules =
      case min_length = rules |> Fulib.get(:min_length) do
        %{value: min_length} = rule ->
          rules
          |> Fulib.put(:min_length, %{
            value: min_length,
            trim: Fulib.get(rule, :trim, trim),
            chars: Fulib.get(rule, :chars, chars)
          })

        _ ->
          if is_integer(min_length) do
            rules |> Fulib.put(:min_length, %{value: min_length, trim: trim, chars: chars})
          else
            rules
          end
      end

    rules =
      case max_length = rules |> Fulib.get(:max_length) do
        %{value: max_length} = rule ->
          rules
          |> Fulib.put(:max_length, %{
            value: max_length,
            trim: Fulib.get(rule, :trim, trim),
            chars: Fulib.get(rule, :chars, chars)
          })

        _ ->
          if is_integer(max_length) do
            rules |> Fulib.put(:max_length, %{value: max_length, trim: trim, chars: chars})
          else
            rules
          end
      end

    rules
  end

  defp _validate_value(current_value, :presence, true, _rules, opts) do
    Fulib.Validations.Presence.validate(current_value, opts)
  end

  defp _validate_value(current_value, :presence, false, rules, opts) do
    _validate_value(current_value, :blank, true, rules, opts)
  end

  defp _validate_value(current_value, :blank, true, _rules, opts) do
    Fulib.Validations.Absence.validate(current_value, opts)
  end

  defp _validate_value(current_value, :blank, false, rules, opts) do
    _validate_value(current_value, :presence, true, rules, opts)
  end

  defp _validate_value(current_value, :numericality, true, _rules, opts) do
    Fulib.Validations.Numericality.validate(current_value, opts)
  end

  defp _validate_value(current_value, :format_with, rule, rules, opts) do
    Fulib.Validations.Format.validate(
      current_value,
      Fulib.merge(opts, with: rule, message: rules[:format_message])
    )
  end

  defp _validate_value(current_value, :format_email, true, _rules, opts) do
    Fulib.Validations.Format.must_email(current_value, opts)
  end

  defp _validate_value(current_value, :format_email, false, _rules, opts) do
    Fulib.Validations.Format.cannot_email(current_value, opts)
  end

  # defp _validate_value(current_value, :format_mobile, true, _rules, opts) do
  #   Fulib.Validations.Format.must_mobile(current_value, opts)
  # end

  # defp _validate_value(current_value, :format_mobile, false, _rules, opts) do
  #   Fulib.Validations.Format.cannot_mobile(current_value, opts)
  # end

  defp _validate_value(current_value, :format_url, true, _rules, opts) do
    Fulib.Validations.Format.must_url(current_value, opts)
  end

  defp _validate_value(current_value, :format_url, false, _rules, opts) do
    Fulib.Validations.Format.cannot_url(current_value, opts)
  end

  defp _validate_value(current_value, :format_integer, true, _rules, opts) do
    Fulib.Validations.Format.must_integer(current_value, opts)
  end

  defp _validate_value(current_value, :format_integer, false, _rules, opts) do
    Fulib.Validations.Format.cannot_integer(current_value, opts)
  end

  defp _validate_value(current_value, :format_pure_number, true, _rules, opts) do
    Fulib.Validations.Format.must_pure_number(current_value, opts)
  end

  defp _validate_value(current_value, :format_pure_number, false, _rules, opts) do
    Fulib.Validations.Format.cannot_pure_number(current_value, opts)
  end

  defp _validate_value(current_value, :min_length, %{value: min_length}, rules, opts) do
    _validate_value(current_value, :min_length, min_length, rules, opts)
  end

  defp _validate_value(current_value, :min_length, min_length, rules, opts) do
    Fulib.Validations.Length.validate(
      current_value,
      Fulib.merge(opts, min: min_length, trim: !!rules[:trim], chars: !!rules[:chars])
    )
  end

  defp _validate_value(current_value, :max_length, %{value: max_length}, rules, opts) do
    _validate_value(current_value, :max_length, max_length, rules, opts)
  end

  defp _validate_value(current_value, :max_length, max_length, rules, opts) do
    Fulib.Validations.Length.validate(
      current_value,
      Fulib.merge(opts, max: max_length, trim: !!rules[:trim], chars: !!rules[:chars])
    )
  end

  defp _validate_value(current_value, :min_value, rule, rules, opts) do
    if rules && _validate_value(current_value, :numericality, rule, rules, opts) == :ok do
      Fulib.Validations.Range.validate(current_value, Fulib.merge(opts, min: rule))
    else
      :ok
    end
  end

  defp _validate_value(current_value, :max_value, rule, rules, opts) do
    if rules && _validate_value(current_value, :numericality, rule, rules, opts) == :ok do
      Fulib.Validations.Range.validate(current_value, Fulib.merge(opts, max: rule))
    else
      :ok
    end
  end

  defp _validate_value(current_value, :acceptance, true, _rules, opts) do
    Fulib.Validations.Acceptance.must(current_value, opts)
  end

  defp _validate_value(current_value, :acceptance, false, _rules, opts) do
    Fulib.Validations.Acceptance.cannot(current_value, opts)
  end

  defp _validate_value(current_value, :inclusion, rule, _rules, opts) when is_list(rule) do
    Fulib.Validations.Inclusion.validate(current_value, Fulib.merge(opts, in: rule))
  end

  defp _validate_value(current_value, :exclusion, rule, _rules, opts) when is_list(rule) do
    Fulib.Validations.Exclusion.validate(current_value, Fulib.merge(opts, in: rule))
  end

  defp _validate_value(_current_value, _key, _rule, _rules, _options), do: :ok
end
