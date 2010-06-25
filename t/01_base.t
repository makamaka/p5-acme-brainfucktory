
use strict;
use Test::More tests => 8;
use Test::Output;
use utf8;

BEGIN { use_ok('Acme::Brainfucktory') };


my $bf = Acme::Brainfucktory->new();

# from http://search.cpan.org/~dankogai/Language-BF-0.03/lib/Language/BF.pm

$bf->code(<<CODE);
++++++++++[>+++++++>++++++++++>+++>+<<<<-]
>++.>+.+++++++..+++.>++.<<+++++++++++++++.>
.+++.------.--------.>+.>.
CODE

isa_ok( $bf, 'Acme::Brainfucktory' );

stdout_is( sub { $bf->run }, "Hello World!\n", 'compile mode' );

stdout_is( sub { $bf->run(1) }, "Hello World!\n", 'interpret mode' );

stdout_is( sub { $bf->run(0) }, "Hello World!\n", 'compile mode' );

stdout_is( sub { $bf->run(1) }, "Hello World!\n", ' interpret mode retry' );


$bf = Acme::Brainfucktory->new( { code => <<CODE } );
++++++++++
++++++++++
++++++++++
++++++++++
+++++++++.
CODE

stdout_is( sub { $bf->run(0) }, "1", 'new with code' );


$bf = Acme::Brainfucktory->new();

$bf->parse( <<CODE );
++++++++++
++++++++++
++++++++++
++++++++++
+++++++++.
CODE

stdout_is( sub { $bf->run(0) }, "1", 'parse' );

