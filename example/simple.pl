#!perl -w -d:Xslate::Cover
use strict;
use Text::Xslate;

my $tx = Text::Xslate->new(
    path => 'example',
    cache => 0,
);

print $tx->render('hello.tx');

