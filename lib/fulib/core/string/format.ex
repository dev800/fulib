defmodule Fulib.String.Format do
  @pure_number_regex Fulib.Const.pure_number_regex()
  def pure_number?(value) do
    Regex.match?(@pure_number_regex, "#{value}")
  end

  @integer_regex Fulib.Const.integer_regex()
  def integer?(value) do
    Regex.match?(@integer_regex, "#{value}")
  end

  @email_regex Fulib.Const.email_regex()
  def email?(value) do
    Regex.match?(@email_regex, "#{value}")
  end

  @website_url_regex Fulib.Const.website_url_regex()
  def website_url?(value) do
    Regex.match?(@website_url_regex, "#{value}")
  end
end
