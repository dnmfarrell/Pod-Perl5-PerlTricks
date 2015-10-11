use Pod::Perl5::ToHTML;
use Pod::PerlTricks::Grammar;

class Pod::PerlTricks::ToHTML is Pod::Perl5::ToHTML
{
  # these are appended to the bottom of the <body> element
  # see format-code:note
  has @!footnotes = [];

  ########################
  # formatting codes
  ########################
  multi method format-code:data ($match)
  {
    $match.make("<span class=\"data\"></span>");
  }

  multi method format-code:github ($match)
  {
    my $reponame = $match<name>[*-1].made;

    $match.make("<a href=\"https://github.com/{$match.Str}\">{$reponame}</a>");
  }

  multi method format-code:hashtag ($match)
  {
    my $hashtag = $match<name>.made;
    $match.make("<a href=\"https://twitter.com/search?q=$hashtag\">#{$hashtag}</a>");
  }

  # create a footnote to be appended to the document body
  # and an internal link pointing to it using superscript
  multi method format-code:note ($match)
  {
    my $footnote = $match<format-text>.made;
    @!footnotes.push($footnote);
    my $footnote_index = @!footnotes.elems;
    $match.make("<sup><a href=\"#{$footnote_index}\">[{$footnote_index}]</a></sup>");
  }

  multi method format-code:terminal ($match)
  {
    $match.make("<span class=\"terminal\">{$match<format-text>.made}</span>");
  }

  multi method format-code:twitter ($match)
  {
    my $name = $match<name>.made;
    $match.make("<a href=\"https://twitter.com/{$name}\">{$name}</a>");
  }

  # using en.wikipedia.org, what about other langs?
  multi method format-code:wikipedia ($match)
  {
    my $wikiname = $match<singleline-format-text>.made;
    $match.make("<a href=\"https://en.wikipedia.org/wiki/{$wikiname}\">{$wikiname}</a>");
  }

  ########################
  # command directives
  ########################

  # table handling
  multi method command-block:table ($match)
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

  multi method command-block:include ($match)
  {
    my $filepath = $match<format-code><url>.Str.subst(/^file\:\/\//, '');
    die 'Error parsing =include block L<>, should be in the format: L<file://path/to/file.pod>'
      unless $filepath;

    # can't use self - it has state!
    my $actions  = Pod::PerlTricks::ToHTML.new;
    # now parse the file
    my $submatch = Pod::PerlTricks::Grammar.parsefile($filepath, :$actions);
    CATCH { die "Error parsing =include directive $_" }

    # copy any meta directives out of the sub-action class
    for $actions.meta.pairs
    {
      %.meta{$_.key.Str} = $_.value.Str;
    }
    # get the inline pod
    # TODO handle more than 1 pod section ?
    $match.make(self.stringify-match($submatch<pod-section>[0]));
  }

  # new meta directives
  # save in meta to be used in <head> later
  # make an empty string so the encoding is not returned inline
  multi method command-block:chapter ($match)
  {
    %.meta<chapter> = "<meta name=\"chapter\" content=\"{$match<singleline-text>.made}\">";
    $match.make('');
  }

  multi method command-block:title ($match)
  {
    %.meta<title> = "<title>{$match<singleline-text>.made}</title>";
    $match.make('');
  }

  multi method command-block:subtitle ($match)
  {
    %.meta<subtitle> = "<meta name=\"subtitle\" content=\"{$match<singleline-text>.made}\">";
    $match.make('');
  }

  multi method command-block:section ($match)
  {
    %.meta<section> = "<meta name=\"section\" content=\"{$match<singleline-text>.made}\">";
    $match.make('');
  }

  multi method command-block:author-name ($match)
  {
    # "author" is an official metadata name
    %.meta<author-name> = "<meta name=\"author\" content=\"{$match<singleline-text>.made}\">";
    $match.make('');
  }

  multi method command-block:author-bio ($match)
  {
    %.meta<author-bio> = "<meta name=\"author-bio\" content=\"{$match<multiline-text>.made}\">";
    $match.make('');
  }

  multi method command-block:author-image ($match)
  {
    %.meta<author-image> = "<meta name=\"author-image\" content=\"{self.create-img($match<format-code>,['author'])}\">";
    $match.make('');
  }

  multi method command-block:synopsis ($match)
  {
    %.meta<synopsis> = "<meta name=\"description\" content=\"{$match<singleline-text>.made}\">";
    $match.make('');
  }

  multi method command-block:tags ($match)
  {
    %.meta<tags> = "<meta name=\"keywords\" content=\"{$match<name>.values.join(",")}\">";
    $match.make('');
  }

  # date time handling
  multi method date     ($match) { $match.make('') }
  multi method time     ($match) { $match.make('') }
  multi method timezone ($match) { $match.make('') }
  multi method datetime ($match) { $match.make($match.Str) }

  multi method command-block:publish-date ($match)
  {
    %.meta<publish-date> = "<meta name=\"keywords\" content=\"{$match<name>.values.join(",")}\">";
    $match.make('');
  }

  # images
  multi method command-block:image ($match)
  {
    my $link = $match<format-code>;
    $match.make(self.create-img($link));
  }

  # cover-image is like image except it gets the cover class
  multi method command-block:cover-image ($match)
  {
    $match.make(self.create-img($match<format-code>, ['cover']));
  }

  method create-img ($link, @html_classes?)
  {
    my ($url, $text) = ("","");

    if $link<url>:exists and $link<singleline-format-text>:exists
    {
      $text = $link<singleline-format-text>.made;
      $url  = $link<url>.made;
    }
    elsif $link<url>:exists
    {
      $text = $link<url>.made;
      $url  = $link<url>.made;
    }
    else
    {
      die 'Unable to parse L<> format code for create-img';
    }
    my $class_txt = @html_classes.elems ?? " class=\"{@html_classes.join(' ')}\"" !! '';
    return "<img src=\"{$url}\" alt=\"{$text}\"{$class_txt}>";
  }
}
