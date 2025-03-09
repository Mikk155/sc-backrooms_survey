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
    class CEnvironmentInformation : ScriptBaseEntity, CToggleState, CFireTargets
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
            if( key == "m_information" )
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
            return ( CFireTargets(key,value) );
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

        void pictured( CBasePlayer@ player )
        {
            if( player is null )
                return;

            auto vec_ent_to_player = ( pev.origin - player.pev.origin ).Normalize();

            g_EngineFuncs.MakeVectors( player.pev.v_angle );

            float dot_prod = DotProduct( g_Engine.v_forward, vec_ent_to_player );
            float dot_right = DotProduct( g_Engine.v_right,     vec_ent_to_player );
            float dot_updw = DotProduct( g_Engine.v_up,        vec_ent_to_player );

            float angle_yaw = abs( atan2( dot_right, dot_prod ) * 57.29578 );
            float angle_upd = abs( atan2( dot_updw, dot_prod ) * 57.29578 );

            auto total_distance = ( self.Center() - player.pev.origin ).Length();

            if( total_distance < 1000 && angle_yaw <= 60.0 && angle_upd <= 50.0 )
            {
                CPicture@ picture = CPicture( player.pev.origin + player.pev.view_ofs, player.pev.v_angle, self.entindex() );

                if( picture !is null )
                {
                    auto user_data = player.GetUserData();
                    auto pictured_entities = cast<dictionary>( user_data[ "pictures" ] );

                    pictured_entities[ name ] = @picture;
                    user_data[ "pictures" ] = pictured_entities;

                    if( ( self.pev.spawnflags & 2 ) == 0 ) // Don't draw glow sprite.
                    {
                        auto spr = g_EntityFuncs.CreateSprite( ( glow_sprite != "" ? glow_sprite : "sprites/glow01.spr" ), self.pev.origin, true );

                        if( spr !is null )
                        {
                            spr.AnimateAndDie( sprite_framerate);
                            spr.pev.rendermode = sprite_rendermode;
                            spr.pev.renderamt = sprite_renderamt;
                            spr.pev.rendercolor = sprite_rendercolor;
                        }
                    }
                }

                FireTargets( m_trigger_on_picture, player, self, m_usetype, 0, m_delay, m_killtarget );
            }
        }
    }
}
