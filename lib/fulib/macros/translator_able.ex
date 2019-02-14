defmodule Fulib.TranslatorAble do
  # opts:
  #   translator: Fulib.Translator
  #   translator_roots: %{}
  #   domain: "enum_settings"
  defmacro __using__(opts \\ []) do
    quote do
      import Fulib.TranslatorAble

      opts = unquote(opts)
      Module.register_attribute(__MODULE__, :gettext, accumulate: false)
      Module.register_attribute(__MODULE__, :default_locale, accumulate: false)

      Module.put_attribute(
        __MODULE__,
        :gettext,
        Fulib.get(opts, :gettext)
      )

      Module.put_attribute(
        __MODULE__,
        :default_locale,
        Fulib.get(opts, :default_locale)
      )

      def with_locale(locale, fun) do
        old_locale = Gettext.get_locale(@gettext)
        Gettext.put_locale(@gettext, locale)
        result = fun.()
        Gettext.put_locale(@gettext, old_locale)
        result
      end

      # Best.Translator.dgettext()
      def dgettext(domain, msgid, bindings \\ %{}) do
        Gettext.dgettext(@gettext, domain, msgid, bindings)
      end

      defdelegate d(domain, msgid, bindings \\ %{}), to: __MODULE__, as: :dgettext

      @spec current_locale() :: String.t()
      def current_locale, do: Gettext.get_locale(@gettext)

      @spec default_locale() :: String.t()
      def default_locale, do: @default_locale
    end
  end
end
