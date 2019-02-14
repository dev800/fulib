defmodule Fulib.String.UbbFormat do
  @moduledoc """
  discuzz论坛的ubb格式的正文的转换
  """

  @tags %{
    "Audio (Unsized)" => [
      ~r/\[audio\]\s+(.*?)\s+\[\/audio\]/mi,
      "<audio src=\"\\1\" controls=\"controls\" loop=\"loop\"><embed height=\"50\" width=\"100\" src=\"\\1\"></audio>",
      "Display an audio",
      "[audio]http://www.google.com/intl/en_ALL/images/logo.gif[/audio]",
      "audio"
    ],
    "Audio (Unsized) No Spaces" => [
      ~r/\[audio\](.*?)\[\/audio\]/mi,
      "<audio src=\"\\1\" controls=\"controls\" loop=\"loop\"><embed height=\"50\" width=\"100\" src=\"\\1\"></audio>",
      "Display an audio",
      "[audio]http://www.google.com/intl/en_ALL/images/logo.gif[/audio]",
      "audio"
    ],
    "Media (Sized)" => [
      ~r/\[media=(.*?)\](.*?)\[\/media\]/mi,
      "<a href=\"\\2\">\\2</a>",
      "Media",
      "[media=250,360]http://www.google.com/intl/en_ALL/images/logo.gif[/media]",
      "media"
    ],
    "Media (X Sized)" => [
      ~r/\[media=x,(.*?)\](.*?)\[\/media\]/mi,
      "<a href=\"\\2\">\\2</a>",
      "Media",
      "[media=x,250,360]http://www.google.com/intl/en_ALL/images/logo.gif[/media]",
      "media"
    ],
    "Media (SWF Sized)" => [
      ~r/\[media=swf,(\d{1,4})[x|\,](\d{1,4})\]\s*([^\[\<\r\n]+?)\s*\[\/flash\]/mi,
      "<embed src=\"\\3\" style=\"width: \\1px; height: \\2px;\" allownetworking=\"internal\" allowscriptaccess=\"never\" quality=\"high\" bgcolor=\"#ffffff\" wmode=\"transparent\" allowfullscreen=\"true\" type=\"application/x-shockwave-flash\"/>",
      "Display an flash with a set width and height",
      "[flash=250,360]http://www.google.com/intl/en_ALL/images/logo.gif[/flash]",
      "flash"
    ],
    "Font" => [
      ~r/\[font=(.*?)\](.*?)\[\/font\]/mi,
      "<font>\\2</font>",
      "Font family",
      "",
      "font"
    ],
    "Free" => [
      ~r/\[free(:.*)?\](.*?)\[\/free\1?\]/mi,
      "<pre>\\2</pre>",
      "Free text",
      "Look [free]here[/free]",
      "free"
    ],
    "Indent" => [
      ~r/\[indent(:.*)?\](.*?)\[\/indent\1?\]/mi,
      "<span style=\"display: inline-block; text-indent: 2em;\">\\2</span>",
      "Embolden text",
      "Look [indent]here[/indent]",
      "indent"
    ],
    "Bold" => [
      ~r/\[b(:.*)?\](.*?)\[\/b\1?\]/mi,
      "<strong>\\2</strong>",
      "Embolden text",
      "Look [b]here[/b]",
      "bold"
    ],
    "Hide (Other)" => [
      ~r/\[hide(=.+)?\](.*?)\[\/hide\1?\]/mi,
      "<p class=\"l-initial-hidden\">\\2</p>",
      "hidden text",
      "Even my [hide]cat[/hide] was chasing the mailman!",
      "italics"
    ],
    "Italics (Other)" => [
      ~r/\[i(=.+)?\](.*?)\[\/i\1?\]/mi,
      "<em>\\2</em>",
      "Italicize or emphasize text",
      "Even my [i]cat[/i] was chasing the mailman!",
      "italics"
    ],
    "Italics" => [
      ~r/\[i(:.+)?\](.*?)\[\/i\1?\]/mi,
      "<em>\\2</em>",
      "Italicize or emphasize text",
      "Even my [i]cat[/i] was chasing the mailman!",
      "italics"
    ],
    "Underline" => [
      ~r/\[u(:.+)?\](.*?)\[\/u\1?\]/mi,
      "<span style=\"text-decoration:underline;\">\\2</span>",
      "Underline",
      "Use it for [u]important[/u] things or something",
      "underline"
    ],
    "Strikeout" => [
      ~r/\[s(:.+)?\](.*?)\[\/s\1?\]/mi,
      "<del>\\2</del>",
      "Strikeout",
      "[s]nevermind[/s]",
      "strikeout"
    ],
    "Delete" => [
      ~r/\[del(:.+)?\](.*?)\[\/del\1?\]/mi,
      "<del>\\2</del>",
      "Deleted text",
      "[del]deleted text[/del]",
      "delete"
    ],
    "Insert" => [
      ~r/\[ins(:.+)?\](.*?)\[\/ins\1?\]/mi,
      "<ins>\\2</ins>",
      "Inserted Text",
      "[ins]inserted text[/del]",
      "insert"
    ],
    "Code" => [
      ~r/\[code(:.+)?\](.*?)\[\/code\1?\]/mi,
      "<code>\\2</code>",
      "Code Text",
      "[code]some code[/code]",
      "code"
    ],
    "Size" => [
      ~r/\[size=(&quot;|&apos;|)(.*?)\1\](.*?)\[\/size\]/mi,
      "<font size=\"\\2\">\\3</font>",
      "Change text size",
      "[size=20]Here is some larger text[/size]",
      "size"
    ],
    "Color" => [
      ~r/\[color=(&quot;|&apos;|)(\w+|\#\w{6})\1(:.+)?\](.*?)\[\/color\3?\]/mi,
      "<span style=\"color: \\2;\">\\4</span>",
      "Change text color",
      "[color=red]This is red text[/color]",
      "color"
    ],
    "Ordered List" => [
      ~r/\[ol\](.*?)\[\/ol\]/mi,
      "<ol>\\1</ol>",
      "Ordered list",
      "My favorite people (alphabetical order): [ol][li]Jenny[/li][li]Alex[/li][li]Beth[/li][/ol]",
      "orderedlist"
    ],
    "Unordered List" => [
      ~r/\[ul\](.*?)\[\/ul\]/mi,
      "<ul>\\1</ul>",
      "Unordered list",
      "My favorite people (order of importance): [ul][li]Jenny[/li][li]Alex[/li][li]Beth[/li][/ul]",
      "unorderedlist"
    ],
    "List Item" => [
      ~r/\[li\](.*?)\[\/li\]/mi,
      "<li>\\1</li>",
      "List item",
      "See ol or ul",
      "listitem"
    ],
    "List Item (alternative)" => [
      ~r/\[\*(:[^\[]+)?\]([^(\[|\<)]+)/mi,
      "<li>\\2</li>",
      "List item (alternative)",
      "[*]list item",
      "listitem"
    ],
    "Unordered list (alternative)" => [
      ~r/\[list(:.*)?\]((?:(?!\[list(:.*)?\]).)*)\[\/list(:.)?\1?\]/mi,
      "<ul>\\2</ul>",
      "Unordered list item",
      "[list][*]item 1[*] item2[/list]",
      "list"
    ],
    "Ordered list (numerical)" => [
      ~r/\[list=1(:.*)?\](.+)\[\/list(:.)?\1?\]/mi,
      "<ol>\\2</ol>",
      "Ordered list numerically",
      "[list=1][*]item 1[*] item2[/list]",
      "list"
    ],
    "Ordered list (alphabetical)" => [
      ~r/\[list=a(:.*)?\](.+)\[\/list(:.)?\1?\]/mi,
      "<ol sytle=\"list-style-type: lower-alpha;\">\\2</ol>",
      "Ordered list alphabetically",
      "[list=a][*]item 1[*] item2[/list]",
      "list"
    ],
    "Definition List" => [
      ~r/\[dl\](.*?)\[\/dl\]/mi,
      "<dl>\\1</dl>",
      "List of terms/items and their definitions",
      "[dl][dt]Fusion Reactor[/dt][dd]Chamber that provides power to your... nerd stuff[/dd][dt]Mass Cannon[/dt][dd]A gun of some sort[/dd][/dl]",
      "definelist"
    ],
    "Definition Term" => [
      ~r/\[dt\](.*?)\[\/dt\]/mi,
      "<dt>\\1</dt>",
      "List of definition terms",
      "[dt]definition term[/dt]",
      "defineterm"
    ],
    "Definition Definition" => [
      ~r/\[dd\](.*?)\[\/dd\]/mi,
      "<dd>\\1</dd>",
      "Definition definitions",
      "[dd]my definition[/dd/",
      "definition"
    ],
    "Quote" => [
      ~r/\[quote(:.*)?=(?:&quot;)?(.*?)(?:&quot;)?\](.*?)\[\/quote\1?\]/mi,
      "<fieldset><legend>\\2</legend><blockquote>\\3</blockquote></fieldset>",
      "Quote with citation",
      "[quote=mike]Now is the time...[/quote]",
      "quote"
    ],
    "Quote (Sourceless)" => [
      ~r/\[quote(:.*)?\](.*?)\[\/quote\1?\]/mi,
      "<fieldset><blockquote>\\2</blockquote></fieldset>",
      "Quote (sourceclass)",
      "[quote]Now is the time...[/quote]",
      "quote"
    ],
    "Link" => [
      ~r/\[url=(?:&quot;)?(.*?)(?:&quot;)?\](.*?)\[\/url\]/mi,
      "<a target=\"_blank\" href=\"\\1\">\\2</a>",
      "Hyperlink to somewhere else",
      "Maybe try looking on [url=http://google.com]Google[/url]?",
      "link"
    ],
    "Link (Implied)" => [
      ~r/\[url\](.*?)\[\/url\]/mi,
      "<a target=\"_blank\" href=\"\\1\">\\1</a>",
      "Hyperlink (implied)",
      "Maybe try looking on [url]http://google.com[/url]",
      "link"
    ],
    "Link (Automatic)" => [
      ~r/(\A|\s)(https?:\/\/[^\s<]+)/,
      " <a target=\"_blank\" href=\"\\2\">\\2</a>",
      "Hyperlink (automatic)",
      "Maybe try looking on http://www.google.com",
      "link"
    ],
    "Link (Automatic without leading http(s))" => [
      ~r/(\A|\s)(www\.[^\s<]+)/,
      " <a target=\"_blank\" href=\"http://\\2\">\\2</a>",
      "Hyperlink (automatic without leading http(s))",
      "Maybe try looking on www.google.com",
      "link"
    ],
    "Flash (Unsized)" => [
      ~r/\[flash\](.*?)\[\/flash\]/mi,
      "<embed style=\"width: 550px; height: 400px;\" src=\"\\1\" allownetworking=\"internal\" allowscriptaccess=\"never\" quality=\"high\" bgcolor=\"#ffffff\" wmode=\"transparent\" allowfullscreen=\"true\" type=\"application/x-shockwave-flash\"/>",
      "Display an flash with a set width and height",
      "[flash]http://www.google.com/intl/en_ALL/images/logo.gif[/flash]",
      "flash"
    ],
    "Flash (Sized)" => [
      ~r/\[flash=(\d{1,4})[x|\,](\d{1,4})\]\s*([^\[\<\r\n]+?)\s*\[\/flash\]/mi,
      "<embed src=\"\\3\" style=\"width: \\1px; height: \\2px;\" allownetworking=\"internal\" allowscriptaccess=\"never\" quality=\"high\" bgcolor=\"#ffffff\" wmode=\"transparent\" allowfullscreen=\"true\" type=\"application/x-shockwave-flash\"/>",
      "Display an flash with a set width and height",
      "[flash=250,360]http://www.google.com/intl/en_ALL/images/logo.gif[/flash]",
      "flash"
    ],
    "Image (Sized)" => [
      ~r/\[img=(\d{1,4})[x|\,](\d{1,4})\]\s*([^\[\<\r\n]+?)\s*\[\/img\]/mi,
      "<img src=\"\\3\"/>",
      "Display an image with a set width and height",
      "[img=250,360]http://www.google.com/intl/en_ALL/images/logo.gif[/img]",
      "image"
    ],
    "Image (Resized)" => [
      ~r/\[img(:.+)? size=(&quot;|&apos;|)(\d+)x(\d+)\2\](.*?)\[\/img\1?\]/mi,
      "<img src=\"\\5\"/>",
      "Display an image with a set width and height",
      "[img size=96x96]http://www.google.com/intl/en_ALL/images/logo.gif[/img]",
      "image"
    ],
    "Image (Alternative)" => [
      ~r/\[img=([^\[\]].*?)\]/mi,
      "<img src=\"\\1\" alt=\"\" />",
      "Display an image (alternative format)",
      "[img=http://myimage.com/logo.gif]",
      "image"
    ],
    "Image (Aligned)" => [
      ~r/\[img(:.+)? align=(left|right)\](.*?)\[\/img\1?\]/mi,
      "<img src=\"\\3\" alt=\"\" style=\"float: \\2;\" />",
      "Display an aligned image",
      "[img align=right]http://catsweekly.com/crazycat.jpg[/img]",
      "image"
    ],
    "Image" => [
      ~r/\[img(:.+)?\]([^\[\]].*?)\[\/img\1?\]/mi,
      "<img src=\"\\2\" alt=\"\" />",
      "Display an image",
      "Check out this crazy cat: [img]http://catsweekly.com/crazycat.jpg[/img]",
      "image"
    ],
    "YouTube" => [
      ~r/\[youtube\](.*?)\?v=([\w\d\-]+).*?\[\/youtube\]/mi,
      "<object width=\"320\" height=\"265\"><param name=\"movie\" value=\"http://www.youtube.com/v/\\2\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowscriptaccess\" value=\"always\"></param><embed src=\"http://www.youtube.com/v/\\2\" type=\"application/x-shockwave-flash\" allowscriptaccess=\"always\" allowfullscreen=\"true\" width=\"320\" height=\"265\"></embed></object>",
      "Display a video from YouTube.com",
      "[youtube]http://youtube.com/watch?v=E4Fbk52Mk1w[/youtube]",
      "video"
    ],
    "YouTube (Alternative)" => [
      ~r/\[youtube\](.*?)\/v\/([\w\d\-]+)\[\/youtube\]/mi,
      "<object width=\"320\" height=\"265\"><param name=\"movie\" value=\"http://www.youtube.com/v/\\2\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowscriptaccess\" value=\"always\"></param><embed src=\"http://www.youtube.com/v/\\2\" type=\"application/x-shockwave-flash\" allowscriptaccess=\"always\" allowfullscreen=\"true\" width=\"320\" height=\"265\"></embed></object>",
      "Display a video from YouTube.com (alternative format)",
      "[youtube]http://youtube.com/watch/v/E4Fbk52Mk1w[/youtube]",
      "video"
    ],
    "Vimeo" => [
      ~r/\[vimeo\](.*?)\/(\d+)\[\/vimeo\]/mi,
      "<object type=\"application/x-shockwave-flash\" width=\"500\" height=\"350\" data=\"http://www.vimeo.com/moogaloop.swf?clip_id=\\2\"><param name=\"quality\" value=\"best\" /><param name=\"allowfullscreen\" value=\"true\" /><param name=\"scale\" value=\"showAll\" /><param name=\"movie\" value=\"http://www.vimeo.com/moogaloop.swf?clip_id=\\2\" /></object>",
      "Display a video from Vimeo",
      "[vimeo]http://www.vimeo.com/3485239[/vimeo]",
      "video"
    ],
    "Google Video" => [
      ~r/\[gvideo\](.*?)\?docid=([-]{0,1}\d+).*\[\/gvideo\]/mi,
      "<embed style=\"width:400px; height:326px;\" id=\"VideoPlayback\" type=\"application/x-shockwave-flash\" src=\"http://video.google.com/googleplayer.swf?docId=\\2\" flashvars=\"\"> </embed>",
      "Display a video from Google Video",
      "[gvideo]http://video.google.com/videoplay?docid=-2200109535941088987[/gvideo]",
      "video"
    ],
    "Email" => [
      ~r/\[email[^:=]?\](((?!\[\/email\]).)*)\[\/email\]/mi,
      "<a href=\"mailto:\\1\">\\1</a>",
      "Link to email address",
      "[email]wadus@wadus.com[/email]",
      "email"
    ],
    "Email (alternative)" => [
      ~r/\[email[:=]([^\]]+)\](((?!\[\/email\]).)*)(\[\/email\1?\])?/mi,
      "<a href=\"mailto:\\1\">\\2</a>",
      "Link to email address",
      "[email:wadus@wadus.com]Email Me[/email]",
      "email"
    ],
    "Align" => [
      ~r/\[align=(.*?)\](.*?)\[\/align\]/mi,
      "<span class=\"l-align-\\1\" style=\"float:\\1;\">\\2</span>",
      "Align this object using float",
      "Here's a wrapped image: [align=right][img]image.png[/img][/align]",
      "align"
    ],
    "Left" => [
      ~r/\[left(:.+)?\](.*?)\[\/left\1?\]/mi,
      "<div style=\"text-align: left;\">\\2</div>",
      "Aligns contents along the left side",
      "[left]Left-aligned content[/left]",
      "left"
    ],
    "Center" => [
      ~r/\[center(:.+)?\](.*?)\[\/center\1?\]/mi,
      "<div style=\"text-align: center;\">\\2</div>",
      "Aligns contents on the center",
      "[center]Centered content[/center]",
      "center"
    ],
    "Right" => [
      ~r/\[right(:.+)?\](.*?)\[\/right\1?\]/mi,
      "<div style=\"text-align: right;\">\\2</div>",
      "Aligns contents along the right side",
      "[right]Right-aligned content[/right]",
      "right"
    ],
    "Hr Break" => [
      ~r/\[hr\]/mi,
      "<hr />",
      "Inserts line break tag",
      "One[hr]Two[hr]Three lines!",
      "hr"
    ],
    "Line break" => [
      ~r/\[br\]/mi,
      "<br />",
      "Inserts line break tag",
      "One[br]Two[br]Three lines!",
      "br"
    ]
  }

  @doc """
  转换过成HTML
  ## opts
      * escape_html: true
  """
  def to_html(text, opts \\ []) do
    escape_html = Keyword.get(opts, :escape_html, true)

    text =
      if escape_html do
        text |> Fulib.String.HTMLFormat.escape()
      else
        text
      end

    text =
      text
      |> String.replace(~r/\[p=(.*?)\]/mi, "<p>")
      |> String.replace(~r/\n+/, "\n")
      |> String.replace("[p]", "<p>")
      |> String.replace("[/p]", "</p>")
      |> String.replace(~r/\[color=(.*?)\]/mi, "<span style=\"color: \\1\">")
      |> String.replace("[/color]", "</span>")
      |> String.replace(~r/\[backcolor=(.*?)\]/mi, "<span style=\"background: \\1\">")
      |> String.replace("[/backcolor]", "</span>")
      |> String.replace(~r/\[table=(.*?)\]/mi, "<table class='ui-border-table' width=\"\\1\">")
      |> String.replace("[table]", "<table class='ui-border-table'>")
      |> String.replace("[/table]", "</table>")
      |> String.replace(~r/\[tr=(.*?)\]/mi, "<tr>")
      |> String.replace("[tr]", "<tr>")
      |> String.replace("[/tr]", "</tr>")
      |> String.replace(
        ~r/\[td=(\d{1,4})[x|\,](\d{1,4})[x|\,](\d{1,4})\]/mi,
        "<td colspan=\"\\1\" rowspan=\"\\2\" width=\"\\3\">"
      )
      |> String.replace(
        ~r/\[td=(\d{1,4})[x|\,](\d{1,4})\]/mi,
        "<td colspan=\"\\1\" rowspan=\"\\2\">"
      )
      |> String.replace(~r/\[td=(\d{1,4})\]/mi, "<td width=\"\\1\">")
      |> String.replace(~r/\[td=(.*?)\]/mi, "<td>")
      |> String.replace("[td]", "<td>")
      |> String.replace("[/td]", "</td>")

    text =
      @tags
      |> Map.values()
      |> Enum.reduce(text, fn rule, acc ->
        pattern = rule |> Enum.at(0)
        replacement = rule |> Enum.at(1)

        acc |> String.replace(pattern, replacement)
      end)

    text
  end
end
