package Acme::BrainFucktory;

use strict;
use base qw( Language::BF );
use Regexp::Assemble;
use Carp ();


our $VERSION = '0.01';

sub new {
    my ( $class, $opt ) = @_;
    my $bf = bless {}, $class;

    $opt ||= {};

    $bf->set_bf_opts();
    $bf->set_op_table( $opt->{ op_table } );
    $bf->set_regexp();

    $bf->code( $opt->{ code } )   if exists $opt->{ code };
    $bf->input( $opt->{ input } ) if exists $opt->{ input };
    $bf;
}


sub set_bf_opts {
    my $bf = shift;
    $bf->{ bf_opts } = {
        '<' => '$sp--;',
        '>' => '$sp++;',
        '+' => '$data[$sp]++;',
        '-' => '$data[$sp]--;',
        '.' => 'push @out, $data[$sp];',
        ',' => '$data[$sp] = shift @_;',
        '[' => 'while($data[$sp]){',
        ']' => '}',
     };
}


sub set_regexp {
    my $bf = shift;
    my $ra = Regexp::Assemble->new;
    for my $k ( keys %{ $bf->{ op_table } } ) {
        Carp::croak "Invalid op table." if $bf->{ op_table }->{ $k } !~ /[-+><\.,[\]]/;
        $ra->add( '\Q' . $k . '\E' );
    }
    $bf->{ op_re } = $ra->re;
}


sub set_op_table {
    my ( $bf, $op_table ) = @_;
    $bf->{ op_table } = $op_table || {
        '<' => '<',
        '>' => '>',
        '+' => '+',
        '-' => '-',
        '.' => '.',
        ',' => ',',
        '[' => '[',
        ']' => ']',
    };
}


sub code($$) { # copied and modified from Language::BF
    my ( $bf, $code ) = @_;
    my $re = $bf->{ op_re };

    $code =~ s{(?:($re)|(.))}{ defined $1 ? $1 : '' }eg;

    my @codes;

    while ( $code =~ /($re)/g ) {
        next unless length $1;
        push @codes, $1;
    }

    $bf->{code} = \@codes;
    my $coderef = $bf->compile;
    warn $coderef unless ref $coderef;
    $bf->{coderef} = $bf->compile;
    $bf->reset;
    $bf;
}


sub compile($){ # copied and modified from Language::BF
    my $bf  = shift;
    my $src = <<'EOS';
sub { 
my (@data, @out) = ();
my $sp = 0;
EOS
    for my $op ( @{ $bf->{code} } ) {
        Carp::croak "Can't understand op [$op]." unless exists $bf->{ op_table }->{ $op };
        $src .= $bf->{ bf_opts }->{ $bf->{ op_table }->{ $op } } . "\n";
    }
    $src .= <<'EOS';
return @out
}
EOS
    my $coderef = eval $src;
    return $@ ? $@ : $coderef;
}



1;
__END__

=pod

=encoding utf8

=head1 NAME

Acme::BrainFucktory - brainf*ck generator

=head1 SYNOPSIS

    use Acme::BrainFucktory;

    # from http://search.cpan.org/~dankogai/Language-BF-0.03/lib/Language/BF.pm
    my $bf = Acme::BrainFucktory->new();

    $bf->code(<<CODE);
    ++++++++++[>+++++++>++++++++++>+++>+<<<<-]
    >++.>+.+++++++..+++.>++.<<+++++++++++++++.>
    .+++.------.--------.>+.>.
    CODE

    $bf->run;
    $bf->output; # "Hello World!\n"

    # from http://d.hatena.ne.jp/tokuhirom/20041015/p14
    my $nekomimi = Acme::BrainFucktory->new( {
        op_table => {
            'ネコミミ！'                    => '>',
            'ネコミミモード'                => '<',
            'おにいさま'                    => '+',
            '私のしもべー'                  => '-',
            'や・く・そ・く・よ'            => '.',
            'フルフルフルムーン'            => ',',
            'キスキス…'                    => '[',
            'キス…したくなっちゃった…'    => ']',
        },
    } );

    $nekomimi->code(<<CODE);
    おにいさまおにいさまおにいさまおにいさまキスキス…ネコミミ！おにいさまおにいさま
    おにいさまおにいさまキスキス…ネコミミ！おにいさまおにいさまおにいさまおにいさま
    ネコミミ！おにいさまおにいさまおにいさまおにいさまおにいさまおにいさまネコミミ！
    おにいさまおにいさまネコミミモードネコミミモードネコミミモード私のしもべー
    キス…したくなっちゃった…ネコミミ！おにいさまおにいさまネコミミ！
    おにいさま
    ネコミミモードネコミミモードネコミミモード私のしもべーキス…したくなっちゃった…
    ネコミミ！ネコミミ！や・く・そ・く・よネコミミ！おにいさまや・く・そ・く・よ
    おにいさまおにいさまおにいさまおにいさまおにいさまおにいさまおにいさま
    や・く・そ・く・よや・く・そ・く・よおにいさまおにいさまおにいさま
    や・く・そ・く・よ
    ネコミミ！や・く・そ・く・よネコミミモードネコミミモード私のしもべー
    ネコミミモード
    おにいさまおにいさまおにいさまおにいさまキスキス…ネコミミ！おにいさまおにいさま
    おにいさまおにいさまネコミミモード私のしもべーキス…したくなっちゃった…ネコミミ！
    や・く・そ・く・よネコミミ！や・く・そ・く・よおにいさまおにいさま
    おにいさま
    や・く・そ・く・よ私のしもべー私のしもべー私のしもべー私のしもべー
    私のしもべー
    私のしもべーや・く・そ・く・よ私のしもべー私のしもべー私のしもべー
    私のしもべー
    私のしもべー私のしもべー私のしもべー私のしもべーや・く・そ・く・よ
    ネコミミ！
    おにいさまや・く・そ・く・よ
    CODE
    
    $nekomimi->run;
    $nekomimi->output; # "Hello World!";


=head1 DESCRIPTION

Welcome to BrainF*ck factory.

=head1 METHODS

=head2 new

    $bf = Acme::BrainFucktory->new();

Constructor. Default by brainf*ck!

=over

=item op_table

=back

=head2 code

Set your terrible code in your terrible language!

=head2 run

Run your terrible code in your terrible language!

=head2 output

Output your terrible result in your terrible language!

=head1 TODO

All Language::BF methods.

=head1 SEE ALSO

L<Language::BF>,
L<Regexp::Assemble>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

