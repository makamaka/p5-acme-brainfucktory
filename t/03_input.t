
use Test::More 'no_plan';
use Test::Output;
use strict;
use utf8;

BEGIN { use_ok('Acme::BrainFucktory') };

my $fb = Acme::BrainFucktory->new();

# from http://search.cpan.org/~dankogai/Language-BF-0.03/lib/Language/BF.pm


$fb->code(<<CODE);
,+.,++.
CODE

tie *Input, 'TestStdin', 'abcd';

$fb->input( *Input );

stdout_is( sub { $fb->run(0) }, "bd", 'compile mode' );

stdout_is( sub { $fb->run(1) }, "df", 'compile mode' );

#print $fb->as_perl;

#$fb->reset;

#$fb->input( *STDIN );

#$fb->run(1);

#print $fb->output, "\n";

#is( $fb->output, "Hello World!\n", 'default' );

#print getc(*STDIN);
#print chr getc(*STDIN);


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
