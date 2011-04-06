package Devel::Xslate::Cover;
use 5.008_001;
use Any::Moose;

our $VERSION = '0.01';

BEGIN {
    $ENV{XSLATE} ||= '';
    $ENV{XSLATE} .= ':save_src';
}

use Text::Xslate::PP; # enable the PP engine
use Text::Xslate::PP::Const;
use Text::Xslate::PP::Opcode;
use Text::Xslate::Util qw(p);
use Text::Xslate;

use List::Util qw(max);
use Carp       qw(croak);

has 'data' => (
    is  => 'rw',
    isa => 'HashRef',

    trigger => sub {
        my($self) = @_;
        $self->clear_coverage();
    },

    lazy    => 1,
    default => sub { +{} },
);

has 'coverage' => (
    is  => 'ro',
    isa => 'HashRef',

    clearer => 'clear_coverage',

    lazy    => 1,
    builder => '_build_coverage',
);


our $Reporter;

BEGIN {
    if($^P) { # under -d:Xslate::Cover switch
        $Reporter = __PACKAGE__->new();
    }
    $^P = 0; # clear off the debugging flag for -d:Xslate::Cover
}

END {
    if(defined $Reporter) {
        $Reporter->report(\*STDERR);
    }
}

__PACKAGE__->setup();

sub setup {
    foreach my $opcode(@Text::Xslate::PP::Const::OPCODE) {
        my $origop = $opcode;
        my $newop = sub {
            my($st) = @_;
            if(defined $Reporter) {
                my $o = $st->{code}[ $st->{pc} ];
                $o->{code_ix} = $st->{pc};
                my $d = $Reporter->data->{ $o->{file} } ||= {
                    raw    => [],
                    len    => scalar(@{$st->{code}}),
                    code   => $st->code,
                    source => $st->engine->{source}{$o->{file}},
                };
                push @{$d->{raw}}, $o;
            }
            goto &{$origop};
        };
        $opcode = $newop;
    }
    return;
}

sub reset :method {
    my($self) = @_;
    $self->data({});
    return;
}

sub _build_coverage {
    my($self) = @_;

    my %cov;
    my $data = $self->data;
    while(my($filename, $d) = each %{$data}) {
        my $len  = $d->{len};
        my $raw  = $d->{raw};
        my $code = $d->{code};

        my %covered;   # based on code_ix

        foreach my $o(@{$raw}) {
            $covered{$o->{code_ix}} = $o->{line};
        }

        my %uncovered;
        foreach my $ix(0 .. scalar(@{$code}) - 1) {
            if(not exists $covered{$ix}) {
                $uncovered{ $code->[$ix]{line} }++;
            }
        }

        $cov{$filename} = {
            stats     => scalar(keys %covered) / ( $len - 1 ),
            uncovered => [ sort { $a <=> $b } keys %uncovered ],
            source    => $d->{source},
        };
    }
    return \%cov;
}

sub _log10 {
    my($n) = @_;
    return log($n) / log(10);
}

sub coverage_of {
    my($self, $filename) = @_;
    my $cov   = $self->coverage->{$filename};
    my $stats = sprintf '  %-20s %6.02f%%',
        $filename, $cov->{stats} * 100;

    my $lines = '';
    if(my $src = $cov->{source}) {
        my @l         = split /\n/, $src;
        my $uncovered = $cov->{uncovered};

        $lines = "\n";
        my $line_width  = max(2, int _log10(scalar @l));
        foreach my $lineno(@{ $uncovered }) {
            $lines .= sprintf "    %0*d: %s\n",
                $line_width, $lineno, $l[ $lineno - 1 ];
        }
    }

    return $stats . $lines;
}

sub report {
    my($self, $out) = @_;
    $out or croak('You must pass a filehandle');

    printf $out "Coverage (%s):\n", ref($self);

    my $data = $self->data;
    foreach my $filename(sort keys %{$data}) {
        print $out $self->coverage_of($filename), "\n";
    }
    return;
}

sub report_as_string {
    my($self) = @_;
    open my $fh, '>', \my $str;
    $self->report($fh);
    close $fh;
    return $str;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Devel::Xslate::Cover - Perl extention to do something

=head1 VERSION

This document describes Devel::Xslate::Cover version 0.01.

=head1 SYNOPSIS

    perl -d:Xslate::Cover script.pl

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Dist::Maker::Template::Default>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
