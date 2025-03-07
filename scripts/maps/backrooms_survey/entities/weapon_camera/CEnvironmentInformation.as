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

namespace camera
{
    class CEnvironmentInformation : ScriptBaseEntity, CToggleState, CFireTarget
    {
        string buffer;
        string name;

        string m_trigger_on_picture;
        string m_trigger_on_watch;

        float m_watch_time = 10.0f;

        bool target_has_rendermode;
        RenderModes target_rendermode;

        int target_renderamt;
        bool target_has_renderamt;

        Vector target_rendercolor;
        bool target_has_rendercolor;

        RenderFX target_renderfx;
        bool target_has_renderfx;

        string glow_sprite;
        float sprite_framerate = 2.0f;
        int sprite_rendermode = kRenderGlow;
        float sprite_renderamt = 255;
        Vector sprite_rendercolor = Vector( 255, 0, 0 );

        bool KeyValue( const string& in key, const string& in value )
        {
            if( CFireTarget( key, value ) )
            {
                return true;
            }
            else if( key == "m_information" )
            {
                if( value.EndsWith( ".txt" ) )
                {
                    string szpath;
                    snprintf( szpath, "scripts/maps/backrooms_survey/data/%1", value );

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
                    else
                    {
                        #if SERVER
                            m_Logger.warn( "Couldn't open file {} for env_info", { szpath } );
                        #endif
                    }
                }
                else
                {
                    buffer = value;
                }
                return true;
            }
            else if( key == "name" )
            {
                name = value;
                return true;
            }
            else if( key == "m_watch_time" )
            {
                m_watch_time = atof(value);
                return true;
            }
            else if( key == "m_trigger_on_picture" )
            {
                m_trigger_on_picture = value;
                return true;
            }
            else if( key == "m_trigger_on_watch" )
            {
                m_trigger_on_watch = value;
                return true;
            }
            else if( key == "target_rendermode" )
            {
                target_rendermode = RenderModes( atoi( value ) );
                target_has_rendermode = true;
                return true;
            }
            else if( key == "target_renderamt" )
            {
                target_renderamt = Math.clamp( 0, 255, atoi( value ) );
                target_has_renderamt = true;
                return true;
            }
            else if( key == "target_rendercolor" )
            {
                g_Utility.StringToVector( target_rendercolor, value );
                target_has_rendercolor = true;
                return true;
            }
            else if( key == "target_renderfx" )
            {
                target_renderfx = RenderFX( atoi( value ) );
                target_has_renderfx = true;
                return true;
            }
            else if( key == "glow_sprite" )
            {
                glow_sprite = value;
                return true;
            }
            else if( key == "sprite_framerate" )
            {
                sprite_framerate = atof( value );
                return true;
            }
            else if( key == "sprite_rendermode" )
            {
                sprite_rendermode = atoi( value );
                return true;
            }
            else if( key == "sprite_renderamt" )
            {
                sprite_renderamt = atof( value );
                return true;
            }
            else if( key == "sprite_rendercolor" )
            {
                g_Utility.StringToVector( sprite_rendercolor, value );
                return true;
            }
            return false;
        }

        void Precache()
        {
            if( glow_sprite != "" )
                g_Game .PrecacheModel( glow_sprite );
        }

        void Spawn()
        {
            Precache();
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );

            information_entities.insertLast( self.entindex() );

            #if SERVER
                m_Logger.trace( "Inserted env_info entity {} as {} with data:\n{}\n", { self.entindex(), name, buffer } );
            #endif
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
        {
            shouldtoggle( use_type );
        }
    }
}
