#!/usr/bin/env perl6
use Test;
use lib 'lib';
use Pod::PerlTricks::Grammar;

plan 2;

use Pod::PerlTricks::ToHTML; pass 'import module';

ok my $actions = Pod::PerlTricks::ToHTML.new, 'constructor';

my $match = Pod::PerlTricks::Grammar.parsefile('test-corpus/SampleArticle.pod', :$actions);

say $match.made;
