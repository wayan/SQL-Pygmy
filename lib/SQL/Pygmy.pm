package SQL::Pygmy;

use strict;
use warnings;

# ABSTRACT: SQL text kept together with bind values

=pod

=encoding UTF-8

=head1 SYNOPSIS

    use SQL::Pygmy;

    my $sp = SQL::Pygmy->new;

=head1 DESCRIPTION

C<SQL::Pygmy> methods returns and manipulate with SQL pieces. SQL piece is nothing more 
than text (containing positional placeholders C<< ? >>) plus the array of positional parameters.

Except of object returned by SQL::Pygmy method, SQL piece can be:

=over 4

=item *

defined scalar value. It is a piece of SQL having text only and no parameters.

=item *

an array with one or two elements. It stands for placeholder only C<< ? >> 
and single value (and possibly its C<< $bind_type >> or C<< $bind_attr >> (see bind_param in DBI).

=back

=cut

use Scalar::Util qw(blessed);
use Carp qw(croak);
use Ref::Util qw(is_plain_arrayref);

my $PIECE_CLASS = __PACKAGE__ . '::_Piece';
{
    no strict 'refs';
    *{$PIECE_CLASS . '::text'} = sub { return $_[0][0] };
    *{$PIECE_CLASS . '::bindings'} = sub { return $_[0][1] };
}


=head1 Methods

=over 4

=item C<new>

Constructor. So far parameterless.

=cut

sub new {
    my ( $class, $args ) = @_;

    return bless( $args // {}, $class );
}

sub build {
    my ($this, $text, $bindings) = @_;

    return $this->_build($text, $bindings // []);
}


=item C<< text($arg) >>

Extracts text part of the argument

=cut

sub text {
    my ($this, $arg) = @_;

    if (!defined $arg){
        croak "No SQL text in undefined";
    }
    return $arg if ! ref($arg);
    return $arg->text if $this->is_sql($arg);
    return '?' if $this->_is_single_value($arg); 

    croak "Invalid arg passed to text";
}

=item C<< bindings($arg) >>

Extract the bindings as an array reference for whatever can be a SQL piece. 

=cut

sub bindings {
    my ($this, $arg) = @_;

    if (!defined $arg){
        croak "No SQL bindings in undefined";
    }
    return [] if ! ref($arg);
    return $arg->bindings if $this->is_sql($arg);
    return $arg if $this->_is_single_value($arg); 

    croak "Invalid arg passed to bindings";
}

=item C<< concat(@args) >>

Concatenates all SQL pieces together, i.e. join their texts by empty string and merges their bindings.

=cut

sub concat {
    my ( $this, @args ) = @_;

    return $this->_build(
        CORE::join( '', map { $this->text($_) } @args ),
        [ map { @{$this->bindings($_)} } @args ]
    );
}

=item C<< join($sep, @args) >>

Concatenates all SQL pieces together, i.e. join their texts by C<< $sep >> string and merges their bindings.

=cut

sub join {
    my ($this, $sep, @args) = @_;

    my $i = 0;
    return $this->concat(
        map { (($i++? $sep: ()), $_); } @args
    );
}

sub as_sql {
    my ( $this, $arg ) = @_;

    return $this->is_sql($arg)
      ? $arg
      : $this->_build( $this->text($arg), $this->bindings($arg) );
}

=item C<< as_value($arg) >>

Converts the C<< $arg >> to a SQL piece as value, i.e. object returned by SQL::Pygmy methods is left as is,
other value is connverted to single placeholder text C<< '?' >> and bind value (the C<< $arg >>).

=cut

sub as_value {
    my ($this, $arg) = @_;

    return $this->_build('?', [$arg]) if !ref $arg;
    return $arg if $this->is_sql($arg);
    
    croak "Argument cannot be converted to SQL value";
}

=item C<< values(@args) >>

Converts every arg to SQL piece as value (see above), joins the pieces by C<< , >> (comma) and wraps the result into parenthesis. 
Throws an exception if the C<< @args >> is empty.

=cut 

sub values {
    my $this = shift;

    croak "Cannot create empty list of values" if !@_;
    return $this->_with_parens( $this->join( ',', map { $this->as_value($_) } @_ ) );
}


sub is_sql {
    my ($this, $arg) = @_;
    blessed($arg) && $arg->isa($PIECE_CLASS);
}

sub _is_single_value {
    my ( $this, $arg ) = @_;

    return is_plain_arrayref($arg) && ( @$arg == 1 || @$arg == 2 );
}

sub _build {
    my ($this, $text, $bindings ) = @_;
    return bless( [ $text, $bindings // [] ], $PIECE_CLASS);
}

=item C<< true >>

Returns SQL piece which can stand true in WHERE conditions. Basically C<< 1=1 >>.

=cut

sub true { 
    my ($this) = @_; 
    return $this->_build('1=1');
}

=item C<< false >>

Returns SQL piece which can stand false in WHERE conditions. Basically C<< 1=0 >>.

=cut

sub false { 
    my ($this) = @_; 
    return $this->_build('1=0');
}

=item C<< and(@args) >> 

Returns:

=over 4

=item *

C<< $sp->true >> for empty C<< @args >>

=item *

the only element from C<< @args >>, if C<< @args >> contains just one element

=item *

concatenation of the elements from C<< @args >>, 
where each element is put into parenthesis and the elements are joined by C<< ' AND ' >>

=back

=cut

sub and {
    my $this = shift;
    return
       !@_      ? $this->true
      : @_ == 1 ? $_[0]
      :           $this->join( ' AND ', map { $this->_with_parens($_) } @_ );
}

=item C<< or(@args) >> 

=over 4

=item *

C<< $sp->false >> for empty C<< @args >>

=item *

the only element from C<< @args >>, if C<< @args >> contains just one element

=item *

concatenation of the elements from C<< @args >>, 
where each element is put into parenthesis and the elements are joined by C<< ' OR ' >>

=back

=cut

sub or {
    my $this = shift;
    return
       !@_      ? $this->false
      : @_ == 1 ? $_[0]
      :           $this->join( ' OR ', map { $this->_with_parens($_) } @_ );
}

sub value {
    my ($this, $value, @attr) = @_;
    
    return $this->_build( '?', [ @attr? [$value, @attr]: $value ]);
}

sub _with_parens {
    my ($this, $arg) = @_;

    return $this->concat('(', $arg, ')');
}

=item C<< apply($dbh, $arg) >>

Prepares and executes the command on database handler, returns the statement handle. 
Roughly equivalent to:

    my $sth = $dbh->prepare($sp->text($arg));
    $sth->execute(@{$sp->bindings($arg)}); 
    return $sth;

=cut

sub apply {
    my ($this, $dbh, $arg) = @_;

    my $text = $this->text($arg);
    my $bindings = $this->bindings($arg);
    my $sth = $dbh->prepare($text);
    my $p_num = 0;
    for my $bind_value (@$bindings){
        $sth->bind_param(++$p_num, is_plain_arrayref($bind_value)? @$bind_value: $bind_value);
    }
    $sth->execute;
    return $sth;
}

=back

=cut

1;
