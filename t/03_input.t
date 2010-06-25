
use Test::More tests => 5;
use Test::Output;
use strict;
use utf8;

BEGIN { use_ok('Acme::Brainfucktory') };

my $fb = Acme::Brainfucktory->new();


$fb->code(<<CODE);
,+.,++.
CODE

tie *Input, 'TestStdin', 'abcdabcd';

$fb->input( *Input );

stdout_is( sub { $fb->run(0) }, "bd", 'compile mode' );

stdout_is( sub { $fb->run(1) }, "df", 'interpret mode' );

stdout_is( sub { $fb->run(0) }, "bd", 'compile mode retry' );

stdout_is( sub { $fb->run(1) }, "df", 'interpret mode retry' );


package TestStdin;


sub TIEHANDLE {
    my ( $class, $data ) = @_;
    bless { data => [ split//,$data ] }, $class;
}


sub GETC {
    my $c = shift @{ $_[0]->{ data } };
    $c;
}


__END__
