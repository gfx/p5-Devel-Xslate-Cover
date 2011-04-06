#!perl -w
use strict;
use Test::More;

use Devel::Xslate::Cover;
use Text::Xslate;
use Text::Xslate::Util qw(p);

my $r = Devel::Xslate::Cover->new();
local $Devel::Xslate::Cover::Reporter = $r; # enable

my $tx = Text::Xslate->new();

isa_ok $tx, 'Text::Xslate';
isa_ok $tx, 'Text::Xslate::PP';

is $tx->render_string('Hello, world!'), 'Hello, world!';

my $report = $r->report_as_string();
ok $report, 'report()';
note $report;
like $report, qr/ @{[ quotemeta ref($r) ]} /xms;
like $report, qr/ \Q<string>\E [ ]+ \Q100.00%\E /xms;

$r->reset();

is $tx->render_string(<<'T'), 'Hello, world!' . "\n";
Hello, <: if($lang) { :>$lang <: } :>world!
T

$report = $r->report_as_string();

ok $report, 'report()';
note $report;
like $report, qr/ \Q<string>\E /xms
    or diag( $r->dump );
unlike $report, qr/ \Q<string>\E [ ]+ \Q100.00%\E /xms;
like $report, qr/\$lang/;

$r->reset();

is $tx->render_string(<<'T'), 'Hello,world!' . "\n";
Hello,
<:- if($lang) { -:>
    <: $lang :>
<:- } -:>
world!
T

$report = $r->report_as_string();

ok $report, 'report()';
note $report;
like $report, qr/ \Q<string>\E /xms
    or diag( $r->dump );
unlike $report, qr/ \Q<string>\E [ ]+ \Q100.00%\E /xms;
like $report, qr/\$lang/;

$r->reset();
done_testing;
