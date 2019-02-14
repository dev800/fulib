defmodule Fulib.Translator do
  @settings Application.get_env(:fulib, Fulib.Gettext) || []

  use Fulib.TranslatorAble,
    default_locale: @settings[:default_locale] || "en",
    gettext: Fulib.Gettext
end
