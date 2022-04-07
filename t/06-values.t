use strict;
use warnings;

use Test::More;
use Test::Exception;

use SQL::Pygmy;

my $sp = SQL::Pygmy->new;

is_deeply( $sp->values(1), $sp->build( '(?)', [1] ) );

is_deeply( $sp->values( 1, $sp->build('today') ),
    $sp->build( '(?,today)', [1] ) );

dies_ok {
    $sp->values()
} 'values cannot be called on empty list';

done_testing();
