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

namespace fog
{
    class CEnvFog : ScriptBaseEntity, CFireTargets, CToggleState
    {
        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;

            SetThink( ThinkFunction( this.think ) );
            self.pev.nextthink = g_Engine.time + 0.1f;;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );
        }

        fog_type m_type = fog_type::all_players;
        int m_radius = 1024;
        int m_distance_start = 128;
        int m_distance_end = 1024;
        RGBA m_color = RGBA_BLACK;

        bool KeyValue( const string& in key, const string& in value )
        {
            if( key == "m_type" )
            {
                m_type = fog_type( Math.clamp( fog_type::all_players, fog_type::radius, atoi( value ) ) );
                return true;
            }
            else if( key == "m_radius" )
            {
                m_radius = atoi( value );
                return true;
            }
            else if( key == "m_distance_start" )
            {
                m_distance_start = atoi( value );
                return true;
            }
            else if( key == "m_distance_end" )
            {
                m_distance_end = atoi( value );
                return true;
            }
            else if( key == "m_color" )
            {
                array<string> colors = value.Split( " " );

                if( colors.length() > 0 )
                    m_color.r = atoi( colors[0] );
                if( colors.length() > 1 )
                    m_color.g = atoi( colors[1] );
                if( colors.length() > 2 )
                    m_color.b = atoi( colors[2] );

                return true;
            }

            return ( ( CFireTargets(key,value) ) );
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
        {
            switch( m_type )
            {
                case fog_type::all_players:
                {
                    for( int i = 1; i <= g_Engine.maxClients; i++ )
                    {
                        auto player = g_PlayerFuncs.FindPlayerByIndex( i );

                        if( player !is null )
                        {
                            entities[player.entindex()-1] = ( entities[player.entindex()-1] == self.entindex() ? 0 : self.entindex() );
                        }
                    }
                    break;
                }
                case fog_type::activator_only:
                {
                    if( activator is null )
                    {
                        #if SERVER
                            m_Logger.warn( "Null activator for {} at {}", { pev.targetname, pev.origin.ToString() } );
                        #endif
                        break;
                    }

                    if( !activator.IsPlayer() )
                    {
                        #if SERVER
                            m_Logger.warn( "Non-Player activator for {} at {} got {} as activator", { pev.targetname, pev.origin.ToString(), activator.pev.classname } );
                        #endif
                        break;
                    }

                    entities[activator.entindex()-1] = ( entities[activator.entindex()-1] == self.entindex() ? 0 : self.entindex() );
                    break;
                }
                case fog_type::radius:
                {
                    shouldtoggle( use_type );
                    self.pev.nextthink = g_Engine.time;
                    break;
                }
            }
        }

        void think()
        {
            if( !shouldtoggle() )
                return;

            for( int i = 1; i <= g_Engine.maxClients; i++ )
            {
                auto player = g_PlayerFuncs.FindPlayerByIndex( i );

                if( player !is null )
                {
                    // If in range. add to the list
                    if( ( player.pev.origin - pev.origin ).Length() <= m_radius )
                    {
                        entities[player.entindex()-1] = self.entindex();
                    }
                    // If not in range and this entity was in the list. remove it.
                    else if( entities[player.entindex()-1] == self.entindex() )
                    {
                        entities[player.entindex()-1] = 0;
                    }
                }
            }

            self.pev.nextthink = g_Engine.time + 0.1f;
        }
    }
}
