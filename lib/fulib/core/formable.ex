defmodule Fulib.Formable.Verifies do
  defmacro __using__(_opts \\ []) do
    quote do
      import Fulib.Formable.Verifies

      Module.eval_quoted(
        __MODULE__,
        quote do
          defp message(opts, key \\ :message, default) do
            Keyword.get(opts, key, default)
          end

          def verify_range(changeset, field, min_value, max_value, opts \\ []) do
            value = Ecto.Changeset.get_change(changeset, field)

            cond do
              opts[:skip_invalid] && not changeset.valid? ->
                changeset

              Fulib.blank?(value) ->
                changeset

              value >= min_value and value <= max_value ->
                changeset

              true ->
                Ecto.Changeset.add_error(
                  changeset,
                  field,
                  message(opts, "must be between %{min_value}~%{max_value}"),
                  Fulib.merge(opts,
                    validation: :range_invalid,
                    min_value: min_value,
                    max_value: max_value
                  )
                )
            end
          end

          def verify_type(changeset, field, type, opts \\ []) do
            value = Ecto.Changeset.get_change(changeset, field)

            if (opts[:skip_invalid] && not changeset.valid?) ||
                 Fulib.get(value, :__struct__) == type do
              changeset
            else
              Ecto.Changeset.add_error(
                changeset,
                field,
                message(opts, "invalid type"),
                validation: :type_invalid
              )
            end
          end
        end
      )
    end
  end
end

defmodule Fulib.Formable do
  defmacro __using__(opts \\ []) do
    quote do
      use Fulib.Formable.Verifies
      use Fulib.Params.Schema
      alias Ecto.Changeset
      import Ecto.Changeset
      import ShorterMaps

      opts = unquote(opts)

      # 翻译器
      Module.register_attribute(__MODULE__, :translator_domains, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :translator_domains,
        opts
        |> Fulib.get(:translator_domains, [])
        |> Fulib.reverse_merge(
          Application.get_env(:fulib, :translator_domains,
            models: "models",
            model_fields: "model_fields",
            model_errors: "model_errors"
          )
        )
      )

      # 翻译器
      Module.register_attribute(__MODULE__, :translator, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :translator,
        Fulib.get(opts, :translator, Fulib.Translator)
      )

      # 翻译器的对应关系
      Module.register_attribute(__MODULE__, :translator_mapping, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :translator_mapping,
        Fulib.get(opts, :translator_mapping, %{})
      )

      # 翻译器的前缀
      Module.register_attribute(__MODULE__, :translator_prefix, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :translator_prefix,
        Fulib.get(opts, :translator_prefix, __MODULE__)
      )

      Module.eval_quoted(
        __MODULE__,
        quote do
          def perform_action(changeset, action) do
            perform_action(changeset, action, fn changeset -> changeset end)
          end

          def perform_action(changeset, :verify, _) do
            perform_action(changeset, :replace)
          end

          def perform_action(changeset, action, success_fn) do
            case apply_action(changeset, action) do
              {:ok, origin_form} ->
                changeset =
                  case success_fn.(changeset) do
                    %Ecto.Changeset{} = changeset -> changeset
                    _ -> changeset
                  end

                %Fulib.Form{
                  valid?: changeset.errors |> Enum.empty?(),
                  changeset: changeset,
                  entries: Fulib.get(changeset, :entries, %{}, %{}),
                  origin: origin_form,
                  module: __MODULE__,
                  errors: changeset.errors
                }

              {:error, changeset} ->
                %Fulib.Form{
                  valid?: changeset.errors |> Enum.empty?(),
                  changeset: changeset,
                  entries: Fulib.get(changeset, :entries, %{}, %{}),
                  origin: nil,
                  module: __MODULE__,
                  errors: changeset.errors
                }
            end
          end

          def fields, do: __MODULE__.__schema__(:fields)

          def translator, do: @translator

          def translator_prefix, do: @translator_prefix

          def translator_domains, do: @translator_domains

          def translate(%Fulib.Form{} = form, locale \\ nil) do
            @translator.with_locale(locale || @translator.current_locale(), fn ->
              human =
                @translator_domains
                |> Fulib.get(:models)
                |> @translator.dgettext("#{__MODULE__}", [])

              human_fields =
                fields()
                |> Enum.map(fn field_key ->
                  @translator_mapping
                  |> Fulib.get(field_key, field_key)
                  |> case do
                    {prefix, translator_key} ->
                      {
                        field_key,
                        @translator.dgettext(
                          @translator_domains |> Fulib.get(:model_fields),
                          "#{prefix}:#{translator_key}",
                          []
                        )
                      }

                    translator_key ->
                      {
                        field_key,
                        @translator.dgettext(
                          @translator_domains |> Fulib.get(:model_fields),
                          "#{@translator_prefix}:#{translator_key}",
                          []
                        )
                      }
                  end
                end)
                |> Map.new()

              human_errors =
                (form.errors || [])
                |> Enum.map(fn {field_key, {msgid, bindings}} ->
                  human =
                    @translator_domains
                    |> Fulib.get(:model_errors)
                    |> @translator.dgettext(msgid, bindings)

                  {field_key, {msgid, human, bindings}}
                end)
                |> Keyword.new()

              %Fulib.Form{
                form
                | human: human,
                  human_fields: human_fields,
                  human_errors: human_errors
              }
            end)
          end

          def put_entries(changeset, entries \\ []) do
            entries = entries |> Map.new()

            entries =
              changeset
              |> Fulib.get(:entries, %{})
              |> Fulib.merge(entries)

            changeset |> Fulib.put(:entries, entries)
          end

          def put_entry(changeset, field, value) do
            entries =
              changeset
              |> Fulib.get(:entries, %{})
              |> Fulib.put(field, value)

            changeset |> Fulib.put(:entries, entries)
          end

          def get_entry(changeset, field, default_value \\ nil, when_nil \\ nil) do
            changeset
            |> Fulib.get(:entries, %{})
            |> Fulib.get(field, default_value, when_nil)
          end

          def get_entries(changeset, fields) do
            fields
            |> Fulib.to_array()
            |> Enum.reduce(%{}, fn x, acc ->
              case x do
                {field, default} ->
                  Map.put(acc, field, get_entry(changeset, field, default, default))

                field ->
                  Map.put(acc, field, get_entry(changeset, field))
              end
            end)
          end

          def get_param(changeset, field, default \\ nil) do
            get_change(changeset, field, Fulib.get(changeset.data, field, default))
          end

          def get_params(changeset, fields, opts \\ []) do
            fields
            |> Fulib.to_array()
            |> Enum.reduce(%{}, fn x, acc ->
              case x do
                {field, default} ->
                  Map.put(acc, field, get_param(changeset, field, default))

                field ->
                  Map.put(acc, field, get_param(changeset, field))
              end
            end)
            |> Fulib.if_call(Fulib.get(opts, :compact, true), fn changes ->
              changes |> Fulib.Map.compact(opts)
            end)
          end

          @doc """
          ## opts

          ` `:compact` true[true]/false 是否将非空字段过滤掉
          * `:filter_false` true/false[默认] 是否过滤掉false值
          * `:filter_presence` true/false[默认] 是否过滤空字符串
          """
          def get_changes(changeset, fields, opts \\ []) do
            fields
            |> Fulib.to_array()
            |> Enum.reduce(%{}, fn x, acc ->
              case x do
                {field, default} ->
                  Map.put(acc, field, get_change(changeset, field, default))

                field ->
                  Map.put(acc, field, get_change(changeset, field))
              end
            end)
            |> Fulib.if_call(Fulib.get(opts, :compact, true), fn changes ->
              changes |> Fulib.Map.compact(opts)
            end)
          end
        end
      )
    end
  end
end
