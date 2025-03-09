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

namespace vanisher
{
    class CVanisherTargets : ScriptBaseEntity, CToggleState, CFireTargets
    {
        private int m_iplayer;

        CBasePlayer@ m_player
        {
            get const
            {
                auto player = g_EntityFuncs.Instance( m_iplayer );

                if( player !is null )
                {
                    return cast<CBasePlayer@>( player );
                }

                return null;
            }
        }

        private float m_height;

        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );
        }

        bool KeyValue( const string& in key, const string& in value )
        {
            return ( ( CFireTargets(key,value) ) );
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
        {
            shouldtoggle( use_type );
        }

        void teleport( CBasePlayer@ player )
        {
            if( player !is null )
            {
                m_iplayer = player.entindex();

                m_height = player.pev.origin.z;

                player.pev.flags |= ( FL_GODMODE | FL_NOTARGET | FL_FROZEN );

                g_PlayerFuncs.ScreenFade( player, g_vecZero, 5.5, 0.5, 255, FFADE_OUT );

                auto effects = g_EntityFuncs.Create( "_vanisher_effects_", player.pev.origin + g_Engine.v_up * 1, g_vecZero, false, self.edict() );

                string targetname;
                snprintf( targetname, "npc_vanisher_teleport_%1", m_iplayer );
                effects.pev.targetname = targetname;

                FireTargets( targetname, player, self, m_usetype, 0, 4.0f, m_killtarget );

                pev.nextthink = g_Engine.time;
                SetThink( ThinkFunction( this.sink ) );
            }
        }

        void sink()
        {
            auto player = m_player;

            if( player is null )
            {
                SetThink( null );
                return;
            }

            pev.nextthink = g_Engine.time + 0.1f;

            g_EntityFuncs.SetOrigin( player, player.pev.origin - g_Engine.v_up * 0.5 );

            if( player.pev.origin.z + player.pev.view_ofs.z <= m_height )
            {
                player.pev.flags &= ~( FL_GODMODE | FL_NOTARGET | FL_FROZEN );

                player.SetOrigin( pev.origin );
                player.pev.fixangle = FAM_FORCEVIEWANGLES;
                player.pev.angles = player.pev.v_angle = pev.angles;

                #if SERVER
                    m_Logger.trace( "Teleported player {} to {}", { player.pev.netname, pev.origin.ToString() } );
                #endif

                FireTargets( string(pev.target), player, self, m_usetype, 0, m_delay, m_killtarget );

                g_PlayerFuncs.ScreenFade( player, g_vecZero, 0.5, 0.0, 255, FFADE_IN );

                SetThink( null );
            }
        }
    }
}
