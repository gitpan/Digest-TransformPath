#!/usr/bin/perl

use inc::Module::Install;

name           ('Digest-TransformPath');
abstract       ('Create digests describing multi-step data transformation paths');
author         ('Adam Kennedy<cpan@ali.as>');
version_from   ('lib/Digest/TransformPath.pm');
license        ('perl');

requires       ('perl'            => '5.005');
requires       ('Digest::MD5'     => '2.00'  );
build_requires ('Test::More'      => '0.47' );
build_requires ('File::Spec'      => '0.82' );

auto_install();

&WriteAll;
