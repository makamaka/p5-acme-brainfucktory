
use strict;
use Test::More tests => 2;
use Test::Output;
use utf8;

BEGIN { use_ok('Acme::Brainfucktory') };

isa_ok( brainf*ck, 'Acme::Brainfucktory' );

