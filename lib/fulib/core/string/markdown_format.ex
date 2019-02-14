defmodule Fulib.String.MarkdownFormat do
  @moduledoc """
  Markdown格式的正文的转换
  """

  def to_html(text, _opts \\ []) do
    Earmark.as_html!(text, %Earmark.Options{code_class_prefix: "lang-"})
  end
end
