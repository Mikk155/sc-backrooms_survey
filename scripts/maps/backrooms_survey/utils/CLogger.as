class CLogger
{
    string name;

    CLogger( const string& in _name )
    {
        name = _name;
    }

    private string _format_( const string &in fmt, array<string>@ args )
    {
        string str;
        snprintf( str, "[%1] %3\n", this.name, fmt );

        for( uint ui = 0; ui < args.length(); ui++ )
        {
            string value;

            uint index = str.Find( "{}", 0 );

            if( index != String::INVALID_INDEX )
            {
                str = str.SubString( 0, index ) + args[ui] + str.SubString( index + 2 );
            }
        }
        return str;
    }

    void error( const string &in fmt, array<string>@ args )
    {
        g_Game.AlertMessage( at_error, this._format_( fmt, args ) );
    }

    void warn( const string &in fmt, array<string>@ args )
    {
        g_Game.AlertMessage( at_warning, this._format_( fmt, args ) );
    }

    void info( const string &in fmt, array<string>@ args )
    {
        g_Game.AlertMessage( at_console, this._format_( fmt, args ) );
    }

    void trace( const string &in fmt, array<string>@ args )
    {
        g_Game.AlertMessage( at_aiconsole, this._format_( fmt, args ) );
    }
}

CLogger@ g_Logger = CLogger( "Map Scripts" );
