
use Test::More 'no_plan';
use Test::Output;
use strict;
use utf8;

BEGIN { use_ok('Acme::BrainFucktory') };

my $fb = Acme::BrainFucktory->new();


$fb->code(<<CODE);
,+.,++.
CODE

tie *Input, 'TestStdin', 'abcd';

$fb->input( *Input );

stdout_is( sub { $fb->run(0) }, "bd", 'compile mode' );

stdout_is( sub { $fb->run(1) }, "df", 'compile mode' );


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
