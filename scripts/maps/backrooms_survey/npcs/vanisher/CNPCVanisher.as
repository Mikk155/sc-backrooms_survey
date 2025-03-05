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
    class CNPCVanisher : ScriptBaseEntity, CToggleState, CFireTarget
    {
        int m_CineAI;
        int m_iEnemy;

        // Keyvalues
        int m_min_cooldown = 1200;
        int m_max_cooldown = 6000;
        int m_retire_time = 10;

        int m_frags = 100;
        int m_health = 10;

        CBaseMonster@ m_hvanisher
        {
            get const
            {
                if( g_EntityFuncs.IsValidEntity( self.pev.owner ) )
                {
                    return cast<CBaseMonster@>( g_EntityFuncs.Instance( self.pev.owner ) );
                }
                return null;
            }
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
        {
            if( !entity_state( use_type ) )
            {
#if SERVER
                if( m_hvanisher !is null )
                {
                    m_Logger.warn( "Turned off NPC controller but the vanisher npc reference still exists. Removing..." );
                }
#endif
            }
        }

        bool KeyValue( const string& in key, const string& in value )
        {
            if( CFireTarget( key, value ) )
            {
                return true;
            }
            else if( key == "m_min_cooldown" )
            {
                m_min_cooldown = atoi( value );
                return true;
            }
            else if( key == "m_max_cooldown" )
            {
                m_max_cooldown = atoi( value );
                return true;
            }
            else if( key == "m_retire_time" )
            {
                m_retire_time = atoi( value );
                return true;
            }
            return false;
        }

        CBaseMonster@ create_vanisher()
        {
            auto entity = g_EntityFuncs.Create( "monster_zombie", pev.origin, pev.angles, true, self.edict() );

            g_EntityFuncs.DispatchKeyValue( entity.edict(), "freeroam", "2" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "bloodcolor", "1" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "soundlist", "brp/vanisher.gsr" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "model", "models/brp/npcs/vanisher.mdl" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "displayname", "Vanisher" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "targetname", "npc_vanisher" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "health", m_health );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "frags", m_frags );

            g_EntityFuncs.DispatchSpawn( entity.edict() );

            g_EntityFuncs.SetOrigin( entity, self.pev.origin );

            @self.pev.owner = entity.edict();

            return m_hvanisher;
        }

        void Precache()
        {
            // This precaches the gsr and model then removes the entity.
            auto vanisher = create_vanisher();
            g_EntityFuncs.Remove( vanisher );
        }

        void Spawn()
        {
            Precache();

            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );

            if( self.pev.targetname == "" )
                self.pev.targetname = "npc_vanisher_controller";

            SetThink( ThinkFunction( this.state_find_candidate ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        void state_find_candidate()
        {
            if( !entity_state() )
            {
                pev.nextthink = g_Engine.time + 0.1f;
                return;
            }

            array<CBasePlayer@> players = {};

#if SERVER
            array<string> player_names = {};
#endif

            for( int i = 0; i <= g_Engine.maxClients; i++ )
            {
                auto candidate = g_PlayerFuncs.FindPlayerByIndex( i );

                // -TODO Get people on a "unsafe" part of the map. maybe custom keyvalues?
                if( candidate !is null
                and candidate.IsConnected()
                and candidate.IsAlive()
                ) {
#if SERVER
                    m_Logger.trace( candidate.pev.netname );
                    player_names.insertLast( candidate.pev.netname );
#endif
                    players.insertLast( candidate );
                }
            }

            if( players.length() <= 0 )
            {
                pev.nextthink = g_Engine.time + 0.1f;
                return;
            }

#if SERVER
            string str_players_size = "";
            for( uint ui = 0; ui < player_names.length(); ui++ ) {
                str_players_size += "\n{}";
            }
            string str_deb;
            snprintf( str_deb, "Time to summon! Enumerated player candidates: %1", str_players_size );
            m_Logger.trace( str_deb, player_names );
#endif

            auto player = players[ Math.RandomLong( 0, players.length() - 1 ) ];

            if( player !is null )
            {
                pev.nextthink = g_Engine.time + 4.0f;
                m_iEnemy = player.entindex();
                g_EntityFuncs.SetOrigin( self, player.pev.origin );

#if SERVER
                m_Logger.info( "Got candidate {} to summon in {} seconds", { player.pev.netname, ( pev.nextthink - g_Engine.time ) } );
#endif

                SetThink( ThinkFunction( this.state_emerge ) );
                return;
            }

            pev.nextthink = g_Engine.time + 0.1f;
        }

        void state_emerge()
        {
            auto vanisher = create_vanisher();

            if( vanisher !is null )
            {
                vanisher.pev.rendermode = kRenderTransAdd;
                vanisher.pev.renderamt = 0;

                /*
                * Somehow i didn't managed to make this work propertly.
                * Seems the AI is fighting it. i've 1:1 scripted.cpp in the HLSDK but nope.
                * So here's this shity hack as usual spawning stupid entities.
                */

                dictionary kv_pair;
                kv_pair[ "target" ] = string(self.pev.targetname);
                kv_pair[ "targetname" ] = "npc_vanisher_sequence";
                kv_pair[ "m_iszEntity" ] = "npc_vanisher";
                kv_pair[ "m_iszPlay" ] = "ventclimb";
                kv_pair[ "m_iszIdle" ] = "ventclimbidle";
                kv_pair[ "m_flRadius" ] = "512";
                kv_pair[ "m_fMoveTo" ] = "4";
                kv_pair[ "spawnflags" ] = "96"; // ( verride AI | No Interruptions )

                auto CineAI = g_EntityFuncs.CreateEntity( "scripted_sequence", kv_pair, true );

                if( CineAI !is null )
                {
                    m_CineAI = CineAI.entindex();

                    TraceResult tr;
                    g_Utility.TraceLine( vanisher.pev.origin + Vector( 0, 0, 90 ), vanisher.pev.origin + Vector( 0, 0, -90 ), ignore_monsters, vanisher.edict(), tr );
                    g_Utility.DecalTrace( tr, DECAL_SCORCH1 );
                    g_EntityFuncs.SetOrigin( CineAI, tr.vecEndPos );

                    SetThink( ThinkFunction( this.state_onground ) );
                    pev.nextthink = g_Engine.time + 1.4f;
                    return;
                }
            }

            pev.nextthink = g_Engine.time + 0.1f;
        }

        void state_onground()
        {
            auto CineAI = g_EntityFuncs.Instance( m_CineAI );
            m_CineAI = 0;

            auto vanisher = m_hvanisher;

            vanisher.pev.rendermode = kRenderNormal;

            auto direction = ( g_EntityFuncs.Instance( m_iEnemy ).pev.origin - vanisher.pev.origin );
            direction.z = 0;
            g_EngineFuncs.VecToAngles( direction, m_hvanisher.pev.angles );

            if( CineAI !is null )
            {
                CineAI.Use( self, self, USE_TOGGLE, 303 );
            }
            else
            {
                g_EntityFuncs.FireTargets( "npc_vanisher_sequence", self, self, USE_TOGGLE, 303 );
            }

            SetThink( ThinkFunction( this.state_finish_emerge ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        void state_finish_emerge()
        {
            auto vanisher = m_hvanisher;

            pev.nextthink = g_Engine.time + 0.1f;

            if( vanisher.m_scriptState == SCRIPT_PLAYING ) {
                return;
            }

            auto CineAI = g_EntityFuncs.Instance( m_CineAI );

            if( CineAI !is null )
            {
                g_EntityFuncs.Remove( CineAI );
            }

            m_CineAI = 0;

            auto enemy = g_EntityFuncs.Instance( m_iEnemy );
            vanisher.PushEnemy( enemy, enemy.pev.origin );

            SetThink( ThinkFunction( this.state_stalk ) );
        }

        void state_stalk()
        {
            if( !entity_state() ) // Retire if it's been turn off by the mapper.
            {
                SetThink( ThinkFunction( this.state_retire ) );
                pev.nextthink = g_Engine.time + 0.1f;
                return;
            }

            auto vanisher = m_hvanisher;

            if( vanisher.pev.frags <= 0 )
            {
                vanisher.pev.health -= 1.0f;
                if( int(vanisher.pev.health) <= 0 ) // Who the fuck did this a float :madge:
                {
#if SERVER
                    m_Logger.trace( "Run out of health. retiring in {}", { m_retire_time } );
#endif
                    pev.nextthink = g_Engine.time + m_retire_time;
                    SetThink( ThinkFunction( this.state_retire ) );
                    vanisher.pev.health = 1.0f;
                    return;
                }
                else
                {
                    vanisher.pev.frags = m_frags;
                    auto player = g_EntityFuncs.FindEntityInSphere( null, vanisher.pev.origin, 2000, "player", "classname" );
#if SERVER
                    m_Logger.trace( "Lost sight of player enemy. Getting new player {}", { player.pev.netname } );
#endif
                    vanisher.PushEnemy( player, player.pev.origin );
                }
            }
            else if( !vanisher.m_hEnemy.IsValid() || vanisher.m_hEnemy.GetEntity() is null )
            {
                // -TODO Dafuck observers!?
                auto player = g_EntityFuncs.FindEntityInSphere( null, vanisher.pev.origin, 2000, "player", "classname" );
#if SERVER
                m_Logger.trace( "Lost sight of player enemy. Getting new player {}", { player.pev.netname } );
#endif
                vanisher.PushEnemy( player, player.pev.origin );
            }
            else if( !vanisher.m_hEnemy.GetEntity().FVisible( vanisher, false ) )
            {
                vanisher.pev.frags--; // frags defines it's stand time
            }

            pev.nextthink = g_Engine.time + 0.1f;
        }

        void state_retire()
        {
            auto vanisher = m_hvanisher;

            dictionary kv_pair;
            kv_pair[ "killtarget" ] = "npc_vanisher";
            kv_pair[ "targetname" ] = "npc_vanisher";
            kv_pair[ "m_iszEntity" ] = "npc_vanisher";
            kv_pair[ "m_iszPlay" ] = "ventclimbdown";
            kv_pair[ "m_iszIdle" ] = "idle";
            kv_pair[ "m_flRadius" ] = "512";
            kv_pair[ "m_fMoveTo" ] = "1";
            kv_pair[ "spawnflags" ] = "96"; // ( verride AI | No Interruptions )

            auto CineAI = g_EntityFuncs.CreateEntity( "scripted_sequence", kv_pair, true );

            TraceResult tr;
            g_Utility.TraceLine( vanisher.pev.origin + Vector( 0, 0, 90 ), vanisher.pev.origin + Vector( 0, 0, -90 ), ignore_monsters, vanisher.edict(), tr );
            g_Utility.DecalTrace( tr, DECAL_SCORCH1 );

            g_EntityFuncs.SetOrigin( CineAI, tr.vecEndPos );
            CineAI.pev.angles = vanisher.pev.angles;

            m_CineAI = CineAI.entindex();

            pev.nextthink = g_Engine.time + 1.4f;
            SetThink( ThinkFunction( this.state_finish_retiring ) );
        }

        void state_finish_retiring()
        {
            auto CineAI = g_EntityFuncs.Instance( m_CineAI );
            m_CineAI = 0;

            CineAI.Use( self, self, USE_ON, 0 );

            // Set next summon time.
            pev.nextthink = g_Engine.time + float(
                m_min_cooldown + 
                    ( m_max_cooldown - m_min_cooldown ) *
                        ( g_Engine.maxClients - g_PlayerFuncs.GetNumPlayers() ) /
                            ( g_Engine.maxClients - 1 )
            );

#if SERVER
            m_Logger.info( "Vanisher npc gone. summoning again in {}", { ( pev.nextthink - g_Engine.time ) } );
#endif

            SetThink( ThinkFunction( this.state_find_candidate ) );
        }

        void attack( CBasePlayer@ player )
        {
            array<CVanisherTargets@> teleports = {};

            CBaseEntity@ teleport = null;

            while( ( @teleport = g_EntityFuncs.FindEntityByClassname( teleport, "info_vanisher_destination" ) ) !is null )
            {
                auto vanisher_teleport = cast<CVanisherTargets@>( CastToScriptClass( teleport ) );

                if( vanisher_teleport !is null && ( vanisher_teleport.pev.spawnflags & 1 ) == 0 )
                {
                    teleports.insertLast( vanisher_teleport );
                }
            }

            auto size = teleports.length();

            if( size == 0 )
            {
#if SERVER
                m_Logger.error( "No valid \"info_vanisher_destination\" entity.\n" );
#endif
                return;
            }

            teleports[ Math.RandomLong( 0, size - 1 ) ].teleport( player );
        }
    }
}
