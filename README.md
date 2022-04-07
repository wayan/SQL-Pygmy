# NAME

SQL::Pygmy - SQL text kept together with bind values

# VERSION

version 0.01

# SYNOPSIS

    use SQL::Pygmy;

    my $sp = SQL::Pygmy->new;

# DESCRIPTION

`SQL::Pygmy` methods returns and manipulate with SQL pieces. SQL piece is nothing more 
than text (containing positional placeholders `?`) plus the array of positional parameters.

Except of object returned by SQL::Pygmy method, SQL piece can be:

- defined scalar value. It is a piece of SQL having text only and no parameters.
- an array with one or two elements. It stands for placeholder only `?` 
and single value (and possibly its `$bind_type` or `$bind_attr` (see bind\_param in DBI).

# Methods

- `new`

    Constructor. So far parameterless.

- `text($arg)`

    Extracts text part of the argument

- `bindings($arg)`

    Extract the bindings as an array reference for whatever can be a SQL piece. 

- `concat(@args)`

    Concatenates all SQL pieces together, i.e. join their texts by empty string and merges their bindings.

- `join($sep, @args)`

    Concatenates all SQL pieces together, i.e. join their texts by `$sep` string and merges their bindings.

- `as_value($arg)`

    Converts the `$arg` to a SQL piece as value, i.e. object returned by SQL::Pygmy methods is left as is,
    other value is connverted to single placeholder text `'?'` and bind value (the `$arg`).

- `values(@args)`

    Converts every arg to SQL piece as value (see above), joins the pieces by `,` (comma) and wraps the result into parenthesis. 
    Throws an exception if the `@args` is empty.

- `true`

    Returns SQL piece which can stand true in WHERE conditions. Basically `1=1`.

- `false`

    Returns SQL piece which can stand false in WHERE conditions. Basically `1=0`.

- `and(@args)` 

    Returns:

    - `$sp->true` for empty `@args`
    - the only element from `@args`, if `@args` contains just one element
    - concatenation of the elements from `@args`, 
    where each element is put into parenthesis and the elements are joined by `' AND '`

- `or(@args)` 
    - `$sp->false` for empty `@args`
    - the only element from `@args`, if `@args` contains just one element
    - concatenation of the elements from `@args`, 
    where each element is put into parenthesis and the elements are joined by `' OR '`
- `apply($dbh, $arg)`

    Prepares and executes the command on database handler, returns the statement handle. 
    Roughly equivalent to:

        my $sth = $dbh->prepare($sp->text($arg));
        $sth->execute(@{$sp->bindings($arg)}); 
        return $sth;

# AUTHOR

Roman Daniel <roman@daniel.cz>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Roman Daniel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
