defmodule Fulib.Ecto.EnumTypeable do
  defmacro __using__(opts \\ []) do
    quote do
      import Fulib.Model.Extends

      opts = unquote(opts)

      type_module = opts[:type_module] || __MODULE__
      values = Fulib.get(opts, :values, [])

      Module.register_attribute(__MODULE__, :type_module, accumulate: false)
      Module.put_attribute(__MODULE__, :type_module, type_module)

      # 翻译器
      Module.register_attribute(__MODULE__, :translator, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :translator,
        Fulib.get(opts, :translator, Fulib.Translator)
      )

      Module.register_attribute(__MODULE__, :translator_domain, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :translator_domain,
        Fulib.get(opts, :translator_domain, "enum_types")
      )

      Module.register_attribute(__MODULE__, :translator_root, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :translator_root,
        Fulib.get(opts, :translator_root, "#{__MODULE__}@")
      )

      Module.register_attribute(type_module, :values, accumulate: false)
      Module.put_attribute(type_module, :values, values)

      k2v =
        values
        |> Enum.map(fn {key, conf} ->
          {key, conf[:value]}
        end)
        |> Map.new()

      v2k =
        values
        |> Enum.map(fn {key, conf} ->
          {conf[:value], key}
        end)
        |> Map.new()

      valid_values = Map.values(k2v) ++ Map.values(v2k)

      Module.register_attribute(type_module, :k2v, accumulate: false)
      Module.put_attribute(type_module, :k2v, k2v)

      Module.register_attribute(type_module, :v2k, accumulate: false)
      Module.put_attribute(type_module, :v2k, v2k)

      Module.register_attribute(type_module, :valid_values, accumulate: false)
      Module.put_attribute(type_module, :valid_values, valid_values)

      Module.eval_quoted(
        @type_module,
        quote do
          @behaviour Ecto.Type

          def print_gettext do
            Enum.each(@values, fn {key, _} ->
              IO.puts("msgid \"#{@translator_root}#{key}\"")
              IO.puts("msgstr \"\"")
              IO.puts("")
            end)
          end

          def get(key, :human) do
            get_in(@values, [key, :human]) || get_human(key)
          end

          def get(key, field_key) do
            get_in(@values, [key, field_key])
          end

          def get_human(key) do
            @translator.dgettext(@translator_domain, "#{@translator_root}#{key}")
          end

          def select_options(style \\ :array, key_type \\ :atom)

          def select_options(:array, :atom) do
            Enum.map(@values, fn {key, _} ->
              [get_human(key), key]
            end)
          end

          def select_options(:array, :string) do
            Enum.map(@values, fn {key, _} ->
              [get_human(key), Fulib.to_s(key)]
            end)
          end

          def select_options(:map, :atom) do
            Enum.map(@values, fn {key, _} ->
              %{name: get_human(key), key: key}
            end)
          end

          def select_options(:map, :string) do
            Enum.map(@values, fn {key, _} ->
              %{name: get_human(key), key: Fulib.to_s(key)}
            end)
          end

          def translator, do: @translator

          def translator_domain, do: @translator_domain

          def translator_root, do: @translator_root

          def values, do: @values

          def k2v, do: @k2v

          def v2k, do: @v2k

          def type, do: :"Fulib.Ecto.EnumTypeable"

          def cast(nil), do: {:ok, nil}

          def cast(value) when is_binary(value) do
            value |> Fulib.to_atom() |> cast()
          end

          def cast(value) when is_atom(value) do
            if Map.has_key?(@k2v, value) do
              {:ok, value}
            else
              msg =
                "Value `#{inspect(value)}` is not a valid enum for `#{inspect(__MODULE__)}`. " <>
                  "Valid enums are `#{inspect(@valid_values)}`"

              raise Ecto.ChangeError, message: msg
            end
          end

          def cast(value) when is_integer(value) do
            @v2k |> Fulib.get(value) |> cast()
          end

          def cast(_), do: :error

          def load(nil), do: {:ok, nil}

          def load(value) when is_atom(value) do
            {:ok, value}
          end

          def load(value) when is_binary(value) do
            value |> Fulib.to_atom() |> load()
          end

          def load(value) when is_integer(value) do
            @v2k |> Fulib.get(value) |> load()
          end

          def load(_), do: :error

          def dump(nil), do: {:ok, nil}

          def dump(value) when is_integer(value) do
            {:ok, value}
          end

          def dump(value) when is_binary(value) do
            value |> Fulib.to_atom() |> dump()
          end

          def dump(value) when is_atom(value) do
            if v = @k2v |> Fulib.get(value) do
              v |> dump()
            else
              :error
            end
          end

          def dump(_), do: :error
        end
      )
    end
  end
end
