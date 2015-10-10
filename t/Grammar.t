#!/usr/bin/env perl6
# These are tests for the PerlTricks pseudopod grammar

use Test;
use lib 'lib';

plan 21;

use Pod::PerlTricks::Grammar; pass 'import module';

ok my $match
  = Pod::PerlTricks::Grammar.parsefile('test-corpus/SampleArticle.pod'),
  'parse sample article';

ok my $pod = $match<pod-section>[0], "match pod section";

is $pod<command-block>[1]<singleline-text>.Str,
  'Separate data and behavior with table-driven testing',
  'title';

is $pod<command-block>[2]<singleline-text>.Str,
  'Applying DRY to unit testing',
  'subtitle';

is $pod<command-block>[3]<datetime>.Str,
  '2000-12-31T00:00:00',
  'publish-date';

#=include tests
ok my $include = $pod<command-block>[4]<file>.made, 'Extract the =include pod';
is $include<pod-section>[0]<command-block>[0]<singleline-text>, 'brian d foy', 'author-name matches expected';
is $include<pod-section>[0]<command-block>[1]<multiline-text><format-code>[3].Str,
  'G<briandfoy>',
  'Match Github format-code';

is $pod<command-block>[5]<name>.elems, 6, '6 tags found';
is $pod<command-block>[5]<name>[3], 'table', 'matched table tag';

is $pod<command-block>[6]<format-code><url>, 'file://onion_charcoal.png', 'cover-image url';

# paragraph tests
is $pod<paragraph>.elems, 16, 'matched all paragraphs';
is $pod<paragraph>[0]<multiline-text><format-code>[0].Str,
  'N<This is known as W<data-driven-testing>>',
  'match note text';
is $pod<paragraph>[0]<multiline-text><format-code>[0]<format-text><format-code>[0].Str,
  'W<data-driven-testing>',
  'Match Wiki text';

is $pod<paragraph>[13]<multiline-text><format-code>[1].Str,
  'D<tests.t>',
  'Match Data format code text';

is $pod<verbatim-paragraph>.elems, 9, 'matched all verbatim paragraphs';

ok my $table = $pod<command-block>[7], 'table';
is $table<header-row><header-cell>.elems, 3, 'match 3 headings';
is $table<header-row><header-cell>[2].Str, 'ColC', 'match third heading';
is $table<row>[1]<cell>[1].Str, '1234', 'match middle cell';
