
use strict;
use warnings;

use Test::More;
use Test::Exception;
use SQL::Pygmy;

my @calls;

{

    package MY::Handle;

    sub prepare {
        _call( 'prepare', @_ );
        return bless( ['sth'], __PACKAGE__ );
    }
    sub execute    { _call( 'execute',    @_ ); }
    sub bind_param { _call( 'bind_param', @_ ); }
    sub dbh        { bless( ['dbh'], __PACKAGE__ ) }

    sub _call {
        my ( $m, $this, @args ) = @_;
        push @calls, [ $m, @$this, @args ];
    }
}

my $sp = SQL::Pygmy->new;
my $sql =
  $sp->build( "SELECT 1 FROM t WHERE id = ? AND name = ?", [ 1, 'Peter' ] );
$sp->apply( MY::Handle->dbh, $sql );

is_deeply(
    \@calls,
    [
        [ "prepare",    'dbh', "SELECT 1 FROM t WHERE id = ? AND name = ?" ],
        [ "bind_param", 'sth', 1, 1 ],
        [ "bind_param", 'sth', 2, "Peter" ],
        [ "execute",    'sth' ],
    ]
);

done_testing();
