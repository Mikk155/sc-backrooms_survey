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

class CEnvironmentInformation : ScriptBaseEntity
{
    string buffer;
    string name;

    int target_rendermode = -1;
    float target_renderamt = -1;
    Vector target_rendercolor = Vector( -1, -1, -1 );
    int target_renderfx = -1;

    string glow_sprite;
    float sprite_framerate = 2.0f;
    int sprite_rendermode = kRenderGlow;
    float sprite_renderamt = 255;
    Vector sprite_rendercolor = Vector( 255, 0, 0 );

    bool KeyValue( const string& in key, const string& in value )
    {
        if( key == "text_file" )
        {
            if( value.EndsWith( ".txt" ) )
            {
                string szpath;
                snprintf( szpath, "scripts/maps/backrooms_survey/data/%1.txt", value );

                auto file = g_FileSystem.OpenFile( szpath, OpenFile::READ );

                if( file !is null && file.IsOpen() )
                {
                    while( !file.EOFReached() )
                    {
                        string line;
                        file.ReadLine( line );
                        snprintf( buffer, "%1\n%2", buffer, line );
                    }
                }
            }
            else
            {
                buffer = value;
            }
        }
        else if( key == "name" )
        {
            name = value;
        }
        else if( key == "target_rendermode" )
        {
            target_rendermode = atoi( value );
        }
        else if( key == "target_renderamt" )
        {
            target_renderamt = atof( value );
        }
        else if( key == "target_rendercolor" )
        {
            g_Utility.StringToVector( target_rendercolor, value );
        }
        else if( key == "target_renderfx" )
        {
            target_renderfx = atoi( value );
        }
        else if( key == "glow_sprite" )
        {
            glow_sprite = value;
        }
        else if( key == "sprite_framerate" )
        {
            sprite_framerate = atof( value );
        }
        else if( key == "sprite_rendermode" )
        {
            sprite_rendermode = atoi( value );
        }
        else if( key == "sprite_renderamt" )
        {
            sprite_renderamt = atof( value );
        }
        else if( key == "sprite_rendercolor" )
        {
            g_Utility.StringToVector( sprite_rendercolor, value );
        }
        else
        {
            return false;
        }
        return true;
    }

    void Spawn()
    {
        information_entities.insertLast( EHandle( self ) );
        g_Game.AlertMessage( at_console, "Inserted env_info entity %1 as %2 with data:\n%3\n", self.edict(), name, buffer );
    }
}
