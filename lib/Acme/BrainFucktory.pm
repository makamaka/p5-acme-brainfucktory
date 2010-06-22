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

    $bf->set_op_table( $opt->{ op_table } );
    $bf->set_regexp();

    $bf->code( $opt->{ code } )   if exists $opt->{ code };
    $bf->input( $opt->{ input } ) if exists $opt->{ input };
    $bf;
}


sub new_from_file { # copied and modified from Language::BF
    my ( $class, $filename, $opt ) = @_;
    my $bf    = $class->new( $opt );
    my $bfile = $filename or die __PACKAGE__, "->new_from_file(filename)";
    open my $fh, "<", $bfile or die "$bfile:$!";
    my $src = do { local $/; <$fh> };
    close $fh;
    $bf->code($src);
    $bf;
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


sub code { # copied and modified from Language::BF
    my ( $bf, $code ) = @_;
    my $re = $bf->{ op_re };

    $code =~ s{(?:($re)|(.))}{ defined $1 ? $1 : '' }eg;

    my @codes;

    while ( $code =~ /($re)/g ) {
        next unless length $1;
        my $op = $1;
        Carp::croak "Can't understand op [$op]." unless exists $bf->{ op_table }->{ $op };
        push @codes, $bf->{ op_table }->{ $op };
    }

    $bf->{code} = \@codes;
    my $coderef = $bf->compile;
    warn $coderef unless ref $coderef;
    $bf->{coderef} = $bf->compile;
    $bf->reset;
    $bf;
}

*parse = \&code;


sub input {
    my ($bf, $input) = @_;
    $bf->{in} =  $input;
    $bf;
}


sub compile { # copied and modified from Language::BF
    my $bf  = shift;
    my $src = <<'EOS';
sub { 
my (@data, @out) = ();
my $sp = 0;
EOS
    for my $op ( @{ $bf->{code} } ) {
        $src .= {
            '<' => '$sp--;',
            '>' => '$sp++;',
            '+' => '$data[$sp]++;',
            '-' => '$data[$sp]--;',
            '.' => 'push @out, $data[$sp];',
            ',' => '$data[$sp] = getc( $_[0] );',
            '[' => 'while($data[$sp]){',
            ']' => '}',
          }->{$op}
          . "\n";
    }
    $src .= <<'EOS';
return @out
}
EOS
    my $coderef = eval $src;
    return $@ ? $@ : $coderef;
}


sub step { # copied and modified from Language::BF
    my $bf = shift;
    my $op = $bf->{code}[ $bf->{pc} ];
    $bf->{debug}
      and warn sprintf "pc=%d, sp=%d, op=%s", $bf->{pc}, $bf->{sp}, $op;
    {
        '<' => sub { $bf->{sp} -= 1 },
        '>' => sub { $bf->{sp} += 1 },
        '+' => sub { $bf->{data}[ $bf->{sp} ]++ },
        '-' => sub { $bf->{data}[ $bf->{sp} ]-- },
        '.' => sub { push @{ $bf->{out} }, $bf->{data}[ $bf->{sp} ] },
        ',' => sub { $bf->{data}[ $bf->{sp} ] = getc( $bf->{in} ) },
        '[' => sub {
            return if $bf->{data}[ $bf->{sp} ];
            my $nest = 1;
            while ($nest) {
                $bf->{pc} += 1;
                $nest     +=
                    $bf->{code}[ $bf->{pc} ] eq '[' ? +1
                  : $bf->{code}[ $bf->{pc} ] eq ']' ? -1
                  : 0;
                die "matching ] not found!" if $bf->{pc} > scalar @{ $bf->{code} };
            }
        },
        ']' => sub {
            my $nest = 1;
            while ($nest) {
                $bf->{pc} -= 1;
                $nest     -=
                    $bf->{code}[ $bf->{pc} ] eq '[' ? +1
                  : $bf->{code}[ $bf->{pc} ] eq ']' ? -1
                  : 0;
                    die "matching [ not found!" if $bf->{pc} < 0;
            }
            $bf->{pc}--;
        },
    }->{$op}();
    $bf->{pc}++;
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
    おにいさまおにいさまおにいさまおにいさまキスキス…
    ネコミミ！おにいさまおにいさま
    おにいさまおにいさまキスキス…ネコミミ！
    おにいさまおにいさまおにいさまおにいさま
    ネコミミ！おにいさまおにいさまおにいさま
    おにいさまおにいさまおにいさまネコミミ！
    おにいさまおにいさまネコミミモードネコミミモード
    ネコミミモード私のしもべー
    キス…したくなっちゃった…ネコミミ！
    おにいさまおにいさまネコミミ！
    おにいさま
    ネコミミモードネコミミモードネコミミモード
    私のしもべーキス…したくなっちゃった…
    ネコミミ！ネコミミ！や・く・そ・く・よネコミミ！
    おにいさまや・く・そ・く・よ
    おにいさまおにいさまおにいさまおにいさまおにいさま
    おにいさまおにいさま
    や・く・そ・く・よや・く・そ・く・よ
    おにいさまおにいさまおにいさま
    や・く・そ・く・よ
    ネコミミ！や・く・そ・く・よ
    ネコミミモードネコミミモード私のしもべー
    ネコミミモード
    おにいさまおにいさまおにいさまおにいさまキスキス…ネコミミ！
    おにいさまおにいさまおにいさまおにいさまネコミミモード
    私のしもべーキス…したくなっちゃった…ネコミミ！
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

Except for C<new> and C<new_from_file>, methods are same as L<Language::BF>.

=head2 new

    $bf = Acme::BrainFucktory->new();
    
    $bf = Acme::BrainFucktory->new( $hashref );

Constructs a brainf*ck virtual machine.
Options:

=over

=item op_table

A list of opcode for your terrible language.
This is a hash reference must hold values:

C<E<gt>>,
C<E<lt>>,
C<+>,
C<->,
C<.>,
C<,>,
C<[>,
C<]>,

    my $your_lang = Acme::BrainFucktory->new( {
        op_table => {
            1 => '>',
            2 => '<',
            3 => '+',
            4 => '-',
            5 => '.',
            6 => ',',
            7 => '[',
            8 => ']',
        }
    } );

By default Brainf*ck.

=item input

Sets C<STDIN>.

=item code

Your terrible code in your terrible language.

=back

=head2 new_from_file

    $bf = Acme::BrainFucktory->new_from_file( $otp, $filename );

Constructs a brainf*ck virtual machine from BF source file.

=head2 code

    $bf->code( $code );

Set your terrible code in your terrible language!

=head2 parse

Alias to C<code>.

=head2 run

    $bf->run( $boolean );

Run your terrible code in your terrible language!

By default it runs perl-compiled code.
By setting $mode to non-zero value, it runs as an iterpreter.

=head2 output

    $result = $bf->output;

Output your terrible result in your terrible language!

=head1 SEE ALSO

L<Language::BF>,
L<Regexp::Assemble>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

