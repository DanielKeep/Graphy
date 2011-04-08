/**
 * This module contains extensions to the Sqlite3 API.
 */
module util.sqlite3ex;

static import sqlite3c = sqlite3;

import std.stdarg : va_list, va_arg;
import std.string : toString, toStringz;
import std.traits : ParameterTypeTuple;

debug(sqlite3ex_trace) import std.stdio : writefln;

version( build )
{
    pragma(link, "sqlite3");
}


private
{
    // Function to generate blocks of aliases.
    char[] mkalias(char[] prefix, char[] symbols)
    {
        char[] r;
        while( symbols.length > 0 )
        {
            if( symbols[0] == ' ' || symbols[0] == '\t'
                    || symbols[0] == '\r' || symbols[0] == '\n'
                    || symbols[0] == ',' )
                symbols = symbols[1..$];

            else if( symbols.length >= 2 && symbols[0..2] == "//" )
            {
                // Find next newline
                size_t off = symbols.length;
                foreach( i,c ; symbols )
                {
                    if( c == '\r' || c == '\n' )
                    {
                        off = i;
                        break;
                    }
                }
                symbols = symbols[off..$];
            }
            else
            {
                // Find next whitespace or comma
                size_t off = symbols.length;
                foreach( i,c ; symbols )
                {
                    if( c == ' ' || c == '\t'
                            || c == '\r' || c == '\n'
                            || c == ',' )
                    {
                        off = i;
                        break;
                    }
                }

                r ~= "alias sqlite3c."~prefix~symbols[0..off]
                    ~" "~prefix~symbols[0..off]~";\n";
                symbols = symbols[off..$];
            }
        }
        return r;
    }

    // Function to mass-wrap functions
    char[] mkwrapped(char[] tmplname, char[] prefix, char[] symbols)
    {
        char[] r;
        while( symbols.length > 0 )
        {
            if( symbols[0] == ' ' || symbols[0] == '\t'
                    || symbols[0] == '\r' || symbols[0] == '\n'
                    || symbols[0] == ',' )
                symbols = symbols[1..$];

            else if( symbols.length >= 2 && symbols[0..2] == "//" )
            {
                // Find next newline
                size_t off = symbols.length;
                foreach( i,c ; symbols )
                {
                    if( c == '\r' || c == '\n' )
                    {
                        off = i;
                        break;
                    }
                }
                symbols = symbols[off..$];
            }
            else
            {
                // Find next whitespace or comma
                size_t off = symbols.length;
                foreach( i,c ; symbols )
                {
                    if( c == ' ' || c == '\t'
                            || c == '\r' || c == '\n'
                            || c == ',' )
                    {
                        off = i;
                        break;
                    }
                }

                r ~= "alias "~tmplname~"!(sqlite3c."~prefix~symbols[0..off]
                    ~") "~prefix~symbols[0..off]~";\n";
                symbols = symbols[off..$];
            }
        }
        return r;
    }
}

// Functions to wrap functions that return a status code with
// error-checking.
template sqlite3_checked(alias fn)
{
    void sqlite3_checked(ParameterTypeTuple!(fn) args)
    {
        debug(sqlite3ex_trace)
            writefln("util.sqlite3ex." ~ (&fn).stringof[2..$]);
        auto rc = fn(args);
        if( rc )
        {
            static if( is( typeof(args[0]) == sqlite3* )
                    || is( typeof(args[0]) == sqlite3_stmt* ) )
            {
                throw new SqliteException(args[0], rc);
            }
            else
            {
                static assert(false,
                        "can't check function " ~ (&fn).stringof
                        ~ " with arguments "
                        ~ ParameterTypeTuple!(fn).stringof);
            }
        }
    }
}

template sqlite3_checked_step(alias fn)
{
    int sqlite3_checked_step(ParameterTypeTuple!(fn) args)
    {
        debug(sqlite3ex_trace)
            writefln("util.sqlite3ex." ~ (&fn).stringof[2..$]);
        auto rc = fn(args);
        switch( rc )
        {
            case SQLITE_ROW:
            case SQLITE_DONE:
                break;

            default:
                throw new SqliteException(args[0], rc);
        }
        return rc;
    }
}

alias sqlite3c.sqlite3 sqlite3;

mixin(mkalias(`SQLITE_`,
`
    DONE
    ROW

    STATIC
    TRANSIENT
`));

mixin(mkalias(`sqlite3_`,
`
    // Types
    stmt
    value

    // Functions that don't return rc
    column_blob
    column_bytes
    column_bytes16
    column_double
    column_int
    column_int64
    column_text
    column_text16
    column_type
    column_value
    db_handle
    errmsg
    sql
`));

mixin(mkwrapped(`sqlite3_checked`, `sqlite3_`,
`
    clear_bindings
    close
    bind_blob
    bind_double
    bind_int
    bind_int64
    bind_null
    bind_text
    bind_text16
    bind_value
    bind_zeroblob
    finalize
    prepare_v2
    reset
`));

mixin(mkwrapped(`sqlite3_checked_step`, `sqlite3_`,
`
    step
`));

// sqlite3_open is a special-case
void sqlite3_open(char* filename, sqlite3** db)
{
    auto rc = sqlite3c.sqlite3_open(filename, db);
    scope(failure)
    {
        *db = null;
        sqlite3_close(*db);
    }
    if( rc )
        throw new SqliteException(*db, rc);
}

class SqliteException : Exception
{
    this(sqlite3* db, int rc)
    {
        super("sqlite error " ~ .toString(rc)
                ~ "(" ~ .toString(sqlite3_errmsg(db)) ~ ")");
    }

    this(sqlite3_stmt* stmt, int rc)
    {
        super("sqlite error " ~ .toString(rc)
                ~ "(" ~ .toString(sqlite3_errmsg(sqlite3_db_handle(stmt)))
                ~ ") while executing SQL ("
                ~ .toString(sqlite3_sql(stmt)) ~ ")");
    }
}

bool sqlite3_table_exists(sqlite3* db, char[] name)
{
    debug(sqlite3ex_trace)
            writefln("util.sqlite3ex.sqlite3_table_exists(sqlite3*, "
            "char[] name = \"%s\")", name);

    sqlite3_stmt* stmt;
    sqlite3_prepareF(db, &stmt,
        `SELECT COUNT(*) FROM sqlite_master WHERE name=?;`, name);
    scope(exit) sqlite3_finalize(stmt);

    int count;

    sqlite3_step_rows(stmt,
        (vdg Break, sqlite3_stmt* stmt)
        {
            count = sqlite3_column_int(stmt, 0);
            return Break();
        }
    );

    return count > 0;
}

alias void delegate() vdg;
alias void delegate(vdg, sqlite3_stmt*) sqlite3_step_dg;

void sqlite3_step_rows(sqlite3_stmt* stmt, sqlite3_step_dg dg)
{
    debug(sqlite3ex_trace)
        writefln("util.sqlite3ex.step_rows(sqlite3_stmt*, sqlite3_step_dg)");

    bool running = true;

    void Break() { running = false; }

    while( running )
    {
        int rc = sqlite3c.sqlite3_step(stmt);

        switch( rc )
        {
            case SQLITE_DONE:
                running = false;
                break;

            case SQLITE_ROW:
                dg(&Break, stmt);
                break;

            default:
                assert(false);
        }
    }
}

void sqlite3_exec_query(sqlite3* db, char[] sql, sqlite3_step_dg dg)
{
    sqlite3_stmt* stmt;
    sqlite3_prepare_v2(db, sql.ptr, sql.length, &stmt, null);
    scope(exit) sqlite3_finalize(stmt);

    sqlite3_step_rows(stmt, dg);
}

void sqlite3_exec_nonquery(sqlite3* db, char[] sql)
{
    sqlite3_stmt* stmt;
    sqlite3_prepare_v2(db, sql.ptr, sql.length, &stmt, null);
    scope(exit) sqlite3_finalize(stmt);
    
    sqlite3_step(stmt);
}

void sqlite3_exec_nonqueryF(sqlite3* db, char[] sql, ...)
{
    return sqlite3_exec_nonqueryVF(db, sql, _argptr, _arguments);
}

void sqlite3_exec_nonqueryVF(sqlite3* db, char[] sql,
        va_list _argptr, TypeInfo[] _arguments)
{
    sqlite3_stmt* stmt;
    sqlite3_prepareVF(db, &stmt, sql, _argptr, _arguments);
    scope(exit) sqlite3_finalize(stmt);

    sqlite3_step(stmt);
}

void sqlite3_prepareF(sqlite3* db, sqlite3_stmt** stmt, char[] sql, ...)
{
    return sqlite3_prepareVF(db, stmt, sql, _argptr, _arguments);
}

void sqlite3_prepareVF(sqlite3* db, sqlite3_stmt** stmt, char[] sql,
        va_list _argptr, TypeInfo[] _arguments)
{
    sqlite3_prepare_v2(db, sql.ptr, sql.length, stmt, null);
    
    foreach( i,ti ; _arguments )
    {
        if( ti is typeid(bool) )
            sqlite3_bind(*stmt, i+1, va_arg!(bool)(_argptr));
        
        else if( ti is typeid(int) )
            sqlite3_bind(*stmt, i+1, va_arg!(int)(_argptr));
        
        else if( ti is typeid(uint) )
            sqlite3_bind(*stmt, i+1, va_arg!(uint)(_argptr));
        
        else if( ti is typeid(long) )
            sqlite3_bind(*stmt, i+1, va_arg!(long)(_argptr));
        
        else if( ti is typeid(double) )
            sqlite3_bind(*stmt, i+1, va_arg!(double)(_argptr));
        
        else if( ti is typeid(void*) )
            sqlite3_bind(*stmt, i+1, va_arg!(void*)(_argptr));
        
        else if( ti is typeid(char[]) )
            sqlite3_bind(*stmt, i+1, va_arg!(char[])(_argptr));
        
        else if( ti is typeid(ubyte[]) )
            sqlite3_bind(*stmt, i+1, va_arg!(ubyte[])(_argptr));
        
        else
        {
            assert(false, "don't know how to bind values of type "
                    ~ ti.toString);
        }
    }
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, bool v)
{
    sqlite3_bind(stmt, i, v ? 1 : 0);
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, int v)
{
    sqlite3_bind_int(stmt, i, v);
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, uint v)
{
    sqlite3_bind(stmt, i, cast(long) v);
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, long v)
{
    sqlite3_bind_int64(stmt, i, v);
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, double v)
{
    sqlite3_bind_double(stmt, i, v);
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, void* v)
{
    if( v !is null )
        assert(false, "cannot bind non-null pointer to sql statement");

    sqlite3_bind_null(stmt, i);
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, char[] v)
{
    sqlite3_bind_text(stmt, i, v.ptr, v.length, SQLITE_TRANSIENT);
}

void sqlite3_bind(sqlite3_stmt* stmt, size_t i, ubyte[] v)
{
    sqlite3_bind_blob(stmt, i, v.ptr, v.length, SQLITE_TRANSIENT);
}

char[] sqlite3_quote(char[] s)
{
    size_t r_len = s.length;
    foreach( c ; s )
        if( c == '"' ) ++r_len;

    if( r_len == s.length )
    {
        auto r = new char[s.length+2];
        r[0] = r[$-1] = '"';
        r[1..$-1] = s;
        return r;
    }
    else
    {
        auto r = new char[r_len+2];
        r[0] = '"';
        r[$-1] = '"';
        auto r_cur = r[1..$-1];
        foreach( c ; s )
        {
            if( c == '"' )
            {
                r_cur[0] = '\\';
                r_cur = r_cur[1..$];
            }
            r_cur[0] = c;
            r_cur = r_cur[1..$];
        }
        return r;
    }
}

