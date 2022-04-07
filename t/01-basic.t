use strict;
use warnings;

use Test::More;
use Test::Exception;

require_ok('SQL::Pygmy');

my $sp = SQL::Pygmy->new;
ok($sp);

subtest 'extract text from arg' => sub {
    is($sp->text("NULL"), "NULL", "plain text yied itself");
    is($sp->text(["133"]), '?', 'array with single scalar is placeholder');

    my $sql = $sp->build('id > ?', [100]);
    is($sp->text($sql), 'id > ?', 'text  from object');

    dies_ok { $sp->text(undef); } 'With undefined it fails';
    dies_ok { $sp->text([]);  }   'With structure it fails';
    dies_ok { $sp->text([2,3,4]);  }   'With structure it fails';
};


my $v = $sp->value(11);
ok($sp->is_sql($v));
is_deeply($v->text, '?');
is_deeply($v->bindings, [11]);


done_testing();
