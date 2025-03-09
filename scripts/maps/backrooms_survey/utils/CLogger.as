/*
*   - You are free to:
*      - Copy. Redistribute, Transform, Build, Remix or format this material in any kind of form.
*
*   - Under the following terms:
*      - You must keep this header with the credited peoples.
*      - You must not use the material for commercial purposes.
*      - You may indicate if changes were made.
*      - You may have the code open-source.
*
*   Credits:
*       - Mikk155 - Author -
*/

/*
*   This is a simple logger to have things organized and to not be removing messages from the code afterwards
*   If you use this please make sure to remove this for release or use pre proccessors as i do.
*
*   - error
*   - warn
*       - Always print + log
*   - info
*       - developer >= 1
*   - trace
*       - developer >= 2
*/

class CLogger
{
    private string _name_;

    CLogger( const string& in module_name )
    {
        this._name_ = module_name;
        this.trace( "Logger Initialized." );
    }

    private string _format_( const string &in fmt, array<string>@ args, bool write = false )
    {
        string str;
        snprintf( str, "[%1] %2\n", this._name_, fmt );

        for( uint ui = 0; ui < args.length(); ui++ )
        {
            string value;

            uint index = str.Find( "{}", 0 );

            if( index != String::INVALID_INDEX )
            {
                str = str.SubString( 0, index ) + args[ui] + str.SubString( index + 2 );
            }
        }

        if( write )
        {
            auto file = g_FileSystem.OpenFile( "scripts/maps/store/backrooms_survey_log.txt", OpenFile::APPEND );

            if( file !is null )
            {
                auto datetime = DateTime();
                string datestring;
                snprintf( datestring, "%1th at %2:%3 > %4", datetime.GetDayOfMonth(), datetime.GetHour(), datetime.GetMinutes(), str );

                file.Write( datestring );
            }
        }

        return str;
    }

    void error( const string &in fmt, array<string>@ args = {} )
    {
        g_Game.AlertMessage( at_error, this._format_( fmt, args, true ) );
    }

    void warn( const string &in fmt, array<string>@ args = {} )
    {
        g_Game.AlertMessage( at_warning, this._format_( fmt, args, true ) );
    }

    void info( const string &in fmt, array<string>@ args = {} )
    {
        g_Game.AlertMessage( at_console, this._format_( fmt, args ) );
    }

    void trace( const string &in fmt, array<string>@ args = {} )
    {
        g_Game.AlertMessage( at_aiconsole, this._format_( fmt, args ) );
    }

    string entname( CBaseEntity@ entity )
    {
        string name = String::EMPTY_STRING;

        if( entity !is null )
        {
            if( entity.IsPlayer() )
            {
                snprintf( name, "%1", entity.pev.netname );
            }
            else if( entity.IsMonster() )
            {
                snprintf( name, "%1", cast<CBaseMonster@>( entity ).m_FormattedName );

                if( entity.pev.targetname != "" )
                    snprintf( name, "%1 name: %2", entity.pev.targetname );
            }
            else
            {
                snprintf( name, "%1", entity.pev.classname );

                if( entity.pev.targetname != "" )
                    snprintf( name, "%1 name: %2", entity.pev.targetname );
            }
        }

        return name;
    }

    string usename(int usetype)
    {
        switch( usetype )
        {
            case USE_OFF:
                return "0 [USE_OFF]";
            case USE_ON:
                return "1 [USE_ON]";
            case USE_SET:
                return "2 [USE_SET]";
            case USE_TOGGLE:
                return "3 [USE_TOGGLE]";
            case USE_KILL:
            default:
                return "4 [USE_KILL]";
        }
    }
}

CLogger@ g_Logger = CLogger( "Map Scripts" );
