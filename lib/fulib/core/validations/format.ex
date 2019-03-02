defmodule Fulib.Validations.Format do
  # options:
  #   :with
  #   :message
  def cannot_pure_number(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.pure_number?(value) do
        {:error, :cannot_pure_number_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "cannot have the pure number format"
           )}
      else
        :ok
      end
    end
  end

  # options:
  #   :with
  #   :message
  def must_pure_number(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.pure_number?(value) do
        :ok
      else
        {:error, :must_pure_number_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "must have the pure number format"
           )}
      end
    end
  end

  # options:
  #   :with
  #   :message
  def cannot_integer(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.integer?(value) do
        {:error, :cannot_integer_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "cannot have the integer format"
           )}
      else
        :ok
      end
    end
  end

  # options:
  #   :with
  #   :message
  def must_integer(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.integer?(value) do
        :ok
      else
        {:error, :must_integer_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "must have the integer format"
           )}
      end
    end
  end

  # options:
  #   :with
  #   :message
  def cannot_email(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.email?(value) do
        {:error, :cannot_email_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "cannot have the email format"
           )}
      else
        :ok
      end
    end
  end

  # options:
  #   :with
  #   :message
  def must_email(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.email?(value) do
        :ok
      else
        {:error, :must_email_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "must have the email format"
           )}
      end
    end
  end

  # # options:
  # #   :with
  # #   :message
  # def cannot_mobile(value, options \\ []) do
  #   Fulib.Validate.unless_skipping value, options do
  #     if Fulib.String.Format.mobile?(value) do
  #       {:error, :cannot_mobile_format,
  #        Keyword.get(options, :message) ||
  #          Fulib.Translator.dgettext(
  #            "validate",
  #            "cannot have the mobile format"
  #          )}
  #     else
  #       :ok
  #     end
  #   end
  # end

  # # options:
  # #   :with
  # #   :message
  # def must_mobile(value, options \\ []) do
  #   Fulib.Validate.unless_skipping value, options do
  #     if Fulib.String.Format.mobile?(value) do
  #       :ok
  #     else
  #       {:error, :must_mobile_format,
  #        Keyword.get(options, :message) ||
  #          Fulib.Translator.dgettext(
  #            "validate",
  #            "must have the mobile format"
  #          )}
  #     end
  #   end
  # end

  # options:
  #   :with
  #   :message
  def cannot_url(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.website_url?(value) do
        {:error, :cannot_url_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "cannot have the url format"
           )}
      else
        :ok
      end
    end
  end

  # options:
  #   :with
  #   :message
  def must_url(value, options \\ []) do
    Fulib.Validate.unless_skipping value, options do
      if Fulib.String.Format.website_url?(value) do
        :ok
      else
        {:error, :must_url_format,
         Keyword.get(options, :message) ||
           Fulib.Translator.dgettext(
             "validate",
             "must have the url format"
           )}
      end
    end
  end

  # options:
  #   :with
  #   :message
  def validate(value, options) when is_list(options) do
    Fulib.Validate.unless_skipping value, options do
      pattern = Keyword.get(options, :with)

      pattern =
        cond do
          Regex.regex?(pattern) -> pattern
          true -> ~r"#{pattern}"
        end

      if Regex.match?(pattern, value) do
        :ok
      else
        message =
          Keyword.get(options, :message) ||
            Fulib.Translator.dgettext("validate", "must have the correct format")

        {:error, :format_mismatch, message}
      end
    end
  end

  def validate(value, pattern) do
    if Regex.regex?(pattern) do
      validate(value, with: pattern)
    end
  end
end
