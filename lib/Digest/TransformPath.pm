package Digest::TransformPath;

=pod

=head1 NAME

Digest::TransformPath - Implements the TransformPath concept

=head1 ACKNOWLEDGEMENTS

A big thank you goes out to "coraline" (Richard Soderburg) for bringing the
caching mechanism of ccache to my attention, which sparked the idea, and upon
which this module is loosely (very) and conceptually (just barely) based.

=head1 SYNOPSIS

  # Pull the original image from the database
  my $Image = Database->get('Image', 423);
  my $Path  = Digest::TransformPath->new('Image.423');
  
  # Resize the image if bigger than 800x600
  Image::Munge->constrain( $Image, 800, 600 );
  $Path->add('constrain(800x600)');
  
  # Save the file
  my $filename = File::Spec->catfile( 'cropped', $Path->digest(15), $Image->type );
  File::Slurp::write_file( $filename, $Image->data );

=head1 DESCRIPTION

A TransformPath is a complex higher-order key that is designed for use with
chains of functions that sequentially transform a piece of data.

The concept starts with a sizable chunk of data, for example an image, for
which we can determine a unique identifier, and for which we can cheaply
determine if and when the source material has changed.

A series of resource-intensive transforms might be applied to this original
data to produce another piece of data. In the image example, we might
auto-level, crop, scale, rotate, colour-balance and then thumbnail the
image. This transformed data would be put into a cache.

If at some future point we wish to obtain the same image, but would
preferably like to use the cached version, we would have to take the original
image, reapply the transforms, and then compare to the result the first time
around.

Alternatives to this general checking mechanism revolve around storing the
identifier in parellel to the data file, in a database or data file, or
similar schemes the involve similar amounts of complexity.

In the TransformPath concept, a structure is created which contains the
original source identifier, and a short, ordered and unique description of
all of the transformations in the sequence.

This description structure is then serialised and hashed to get a unique and
generally cryptographically secure identifier for the transformed image. This
identifier would typically be used as part of the file name/path for the
transformed image.

To check that the file is unchanged, we merely confirm that the original has
not changed, and then rebuilt the TransformPath digest. If the TransformPath
digest is unchanged, then the transformed image is unchanged, and we can use
the version in the cache, saving ourselves the high expense of running the
transforms again.

If we cannot cheaply tell that the source image has changed, there is a
clean fallback position. By including a digest of the original data inside
the TransformPath object, the final digest changes automatically whenever the
data inside the source file changes.

While this still costs us a digest run each time, this is relatively
affordable compared to doing the transforms as well.

This can be done by either using the initial digest as the source id, or by
adding it as the first transform step. The latter is recommended for most
situations, as this ensures that the source id is static, and won't change.

In many uses of Digest::TransformPath, this is likely to be highly preferable.

=cut

use 5.005;
use strict;
use Digest::MD5 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.00';
}

=pod

=head1 METHODS

=head2 new $id [, $string, ... ]

The C<new> constructor creates a new Digest::TransformPath object.

Returns a new Digest::TransformPath object, or C<undef> if not given a plain
string for the identifier.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $self = bless [ ], $class;

	# Add the id
	$self->add(shift) or return undef;

	# Add any extra transforms
	while ( @_ ) {
		$self->add(shift) or return undef;
	}

	$self;
}

=pod

=head2 add $string

The C<add> method adds a transform description, in the form of a string, to
the TransformPath object.

Returns true, or C<undef> if not passed a string.

=cut

sub add {
	my $self = shift;
	my $step = (defined $_[0] and ! ref $_[0]) ? shift : return undef;
	push @$self, $step;
	1;
}

=pod

=head2 source_id

Returns the original source identifier

=cut

sub source_id { $_[0]->[0] }

=pod

=head2 digest [ $chars ]

The C<digest> method generates an MD5 digest for the object. If passed the
optional $chars integer value, it will trim the 32 byte digest (it uses hex)
down to a shorter length.

=cut

sub digest {
	my $self   = shift;
	my $joined = join "\n", @$self;
	my $digest = Digest::MD5::md5_hex($joined);
	my $chars  = @_ ? shift : return $digest;
	(defined $chars and ! ref $chars and $chars > 0 and $chars <= 32)
		? substr( $digest, 0, $chars )
		: undef;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Digest%3A%3ATransformPath>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright (c) 2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
