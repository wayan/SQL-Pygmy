use strict;
use warnings;

use Test::More;
use Test::Exception;

use SQL::Pygmy;

my $sp = SQL::Pygmy->new;
my $v1 = $sp->concat( 'x=', [10] );
my $v2 = 'y IS NOT NULL';
is_deeply( $sp->and,      $sp->true, 'with no params yields true' );
is_deeply( $sp->and($v1), $v1,       'with single arg yields the arg' );
is_deeply(
    $sp->and( $v1, $v2 ),
    $sp->build( '(x=?) AND (y IS NOT NULL)', [10] ),
    'with more args, they are parenthesised and joined'
);

done_testing;
