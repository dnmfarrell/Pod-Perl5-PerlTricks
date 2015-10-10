use Pod::Perl5::ToHTML;

class Pod::PerlTricks::ToHTML is Pod::Perl5::ToHTML
{
  # these are appended to the bottom of the <body> element
  # see format-code:note
  has @!footnotes = [];

  method TOP ($match)
  {
    my $head = $!meta ?? "\n<head>{$!meta}\n</head>" !! '';
    my $body = "\n<body>\n{stringify-match($match)}\n</body>";
    my $html = "<html>{$head}{$body}\n</html>\n";
    # remove double blank lines
    $match.make($html.subst(/\n ** 3..*/, {"\n\n"}, :g));
  }

  ########################
  # formatting codes
  ########################
  multi method format-code:data ($match)
  {
    $match.make("<span class=\"data\">{$match<format-text>.made}</span>");
  }

  multi method format-code:github ($match)
  {
    my $username = $match<name>[0].made;
    my $reponame = $match<name>[1].made;

    $match.make("<a href=\"https://github.com/$username/$reponame\">$reponame</a>");
  }

  multi method format-code:hashtag ($match)
  {
    my $hashtag = $match<name>.made;
    $match.make("<a href=\"https://twitter.com/search?q=$hashtag\">#$hashtag</a>");
  }

  # create a footnote to be appended to the document body
  # and an internal link pointing to it using superscript
  multi method format-code:note ($match)
  {
    my $footnote = $match<format-text>.made;
    @!footnotes.push($footnote);
    my $footnote_index = @!footnotes.elems;
    $match.make("<sup><a href=\"#$footnote_index\">[$footnote_index]</a></sup>");
  }

  multi method format-code:terminal ($match)
  {
    $match.make("<span class=\"terminal\">{$match<format-text>.made}</span>");
  }

  multi method format-code:twitter ($match)
  {
    my $name = $match<name>.made;
    $match.make("<a href=\"https://twitter.com/$name\">\@$name</a>");
  }

  # using en.wikipedia.org
  # maybe use a =lang directive to drive this (and other things?)
  multi method format-code:wikipedia ($match)
  {
    my $wikiname = $match<singleline-format-text>.amde;
    $match.make("<a href=\"https://en.wikipedia.org/wiki/$wikiname\">$wikiname</a>");
  }

  ########################
  # table handling
  ########################
  method command-block:table ($match)
  {
    my @table_tags = '<table>', $match<header-row>.made;

    for $match<row>.values -> $row
    {
      @table_tags.push("<tr>{$row.made}</tr>");
    }
    @table_tags.push("</table>");
    $match.make(join("\n", @table_tags));
  }
  method header-row ($match)
  {
    my $cells;

    for $match<header-cell>.values -> $cell
    {
      $cells ~= $cell.made;
    }
    $match.make($cells);
  }
  method row ($match)
  {
    my $cells;

    for $match<cell>.values -> $cell
    {
      $cells ~= $cell.made;
    }
    $match.make($cells);
  }
  method header-cell ($match)
  {
    $match.make("<th>{$match}</th>");
  }
  method cell ($match)
  {
    $match.make("<td>{$match}</td>");
  }
}
