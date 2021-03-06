defmodule Fulib.HtmlSanitize.Scrubber.StripTags do
  @moduledoc """
  Strips all tags.
  """

  require Fulib.HtmlSanitize.Scrubber.Meta
  alias Fulib.HtmlSanitize.Scrubber.Meta

  # Removes any CDATA tags before the traverser/scrubber runs.
  Meta.remove_cdata_sections_before_scrub()

  Meta.strip_comments()

  Meta.strip_everything_not_covered()
end
