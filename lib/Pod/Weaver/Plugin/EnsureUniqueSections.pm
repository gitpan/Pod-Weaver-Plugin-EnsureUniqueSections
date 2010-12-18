use strict;
use warnings;
use utf8;

package Pod::Weaver::Plugin::EnsureUniqueSections;
BEGIN {
  $Pod::Weaver::Plugin::EnsureUniqueSections::VERSION = '0.103520';
}
use Moose;
use MooseX::Has::Sugar;
use Moose::Autobox;
use Text::Trim;

use Lingua::EN::Inflect::Number qw(to_S);
use Carp;
with 'Pod::Weaver::Role::Finalizer';
# ABSTRACT: Ensure that POD has no duplicate section headers.


has strict => (
    ro, lazy,
    isa => 'Bool',
    default => sub { 0 },
);

sub _header_key {
    my ($self, $text) = @_;
    if (!$self->strict) {
        # Replace all non-words with a single space
        $text =~ s{\W+}{ }xsmg;
        # Trim leading and trailing whitespace
        $text = trim $text;
        # All to uppercase
        $text = uc $text;
        # Reorder "AND" lists and singularize nouns
        $text = $text
            ->split(qr{ AND }i)
                ->map(sub { m{\W} ? $_ : to_S $_; })
                    ->sort->join(" AND ");
    }
    return $text;
}


sub finalize_document {
    use Smart::Comments;
    my ($self, $document) = @_;
    my $headers = $document->children
        ->grep(sub{ $_->command eq 'head1' })
            ->map(sub{ $_->content });
    my %header_group;
    for my $h (@$headers) {
        push @{$header_group{$self->_header_key($h)}}, $h;
    }

    my $duplicate_headers = [ keys %header_group ]
        ->map(sub{ @{$header_group{$_}} > 1 ? $header_group{$_}->head : () })
            ->sort;
    if (@$duplicate_headers > 0) {
        my $message = "Error: The following headers appear multiple times: '" . $duplicate_headers->join(q{', '}) . q{'};
        croak $message;
    }
}

1;                        # Magic true value required at end of module


=pod

=head1 NAME

Pod::Weaver::Plugin::EnsureUniqueSections - Ensure that POD has no duplicate section headers.

=head1 VERSION

version 0.103520

=head1 SYNOPSIS

In F<weaver.ini>

    [-EnsureUniqueSections]
    strict = 0 ; The default

=head1 DESCRIPTION

This plugin simply ensures that the POD after weaving has no duplicate
top-level section headers. This can help you if you are converting a
dist to Dist::Zilla and Pod::Weaver, and you forgot to remove POD
sections that are now auto-generated.

By default, this module does some tricks to detect similar headers,
such as C<AUTHOR> and C<AUTHORS>. You can turn this off by setting
C<strict = 1> in F<weaver.ini>.

=head1 ATTRIBUTES

=head2 strict

If set to true (1), section headers will only be considered duplicates
if they match exactly. If false (the default), certain similar section
headers will be considered equivalent. The following similarities are
considered (more may be added later):

=over 4

=item All whitespace and punctuation are equivalant

For example, the following would all be considered duplicates of each
other: C< SEE ALSO>, C<SEE ALSO>, C<SEE,ALSO:>.

=item Case-insensitive

For example, C<Name> and C<NAME> would be considered duplicates.

=item Sets of words separated by "AND".

For example, "COPYRIGHT AND LICENSE" would be considered a duplicate
of "LICENSE AND COPYRIGHT".

=item Plurals

"AUTHOR" and "AUTHORS" are the same section. A section header
consisting of multiple words, such as "DISCLAIMER OF WARRANTY", is not
affected by this rule.

This rule uses L<Lingua::EN::Inflect::Number> to interconvert between
singulars and plurals. Hopefully you don't need to make a section
called C<OCTOPI>.

=back

Note that these rules apply recursively, so C<Authors; and
Contributors> would be a duplicate of C< CONTRIBUTORS AND AUTHOR>.

=head1 METHODS

=head2 finalize_document

This method checks the document for duplicate headers, and throws an
error if any are found. If no duplicates are found, it simply does
nothing. It does not modify the POD in any way.

=head1 BUGS AND LIMITATIONS

I would like to convert this to a Dist::Zilla testing plugin, but I
haven't yet figured out how to find all files in a dist with POD and
extract all their headers.

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

