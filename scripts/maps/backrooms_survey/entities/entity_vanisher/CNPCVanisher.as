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
    class CNPCVanisher : ScriptBaseEntity, CToggleState, CFireTargets
    {
        // Keyvalues
        int m_min_cooldown = 1200;
        int m_max_cooldown = 6000;
        int m_retire_time = 10;
        int m_frags = 100;
        int m_health = 10;
        float m_maxspeed = 3.0f;

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
            if( !shouldtoggle( use_type ) )
            {
                #if SERVER
                    if( m_hvanisher !is null )
                    {
                        m_Logger.warn( "Turned off NPC controller but the vanisher npc reference still exists. Removing..." );
                    }
                #endif
            }
            else
            {
                pev.nextthink = g_Engine.time;
            }
        }

        bool KeyValue( const string& in key, const string& in value )
        {
            if( key == "m_min_cooldown" )
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
            else if( key == "m_frags" )
            {
                m_frags = atoi( value );
                return true;
            }
            else if( key == "m_health" )
            {
                m_health = atoi( value );
                return true;
            }
            else if( key == "m_maxspeed" )
            {
                m_maxspeed = atof( value );
                return true;
            }
            return ( CFireTargets(key,value) );
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

            SetThink( ThinkFunction( this.state_emerge ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        void state_emerge()
        {
            pev.nextthink = g_Engine.time + 0.1f;

            if( !shouldtoggle() )
            {
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
                if( candidate !is null && candidate.IsConnected() && candidate.IsAlive() )
                {
                    #if SERVER
                        m_Logger.trace( candidate.pev.netname );
                        player_names.insertLast( candidate.pev.netname );
                    #endif

                    players.insertLast( candidate );
                }
            }

            if( players.length() > 0 )
            {
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

                Vector vec_destination;

                // Try to get a random position. otherwise just do the spiral shit.
                TraceResult tr;
                g_Utility.TraceLine( player.pev.origin + player.pev.view_ofs, player.pev.origin +
                    Vector( Math.RandomLong( -512, 512 ), Math.RandomLong( -512, 512 ), 0 ), dont_ignore_monsters, player.edict(), tr );

                if( tr.flFraction >= 1.0 )
                {
                    g_Utility.TraceHull( tr.vecEndPos, tr.vecEndPos, dont_ignore_monsters, human_hull, null, tr );

                    if( tr.fStartSolid == 0 && tr.fAllSolid == 0 )
                        vec_destination = tr.vecEndPos;
                }

                if( vec_destination != g_vecZero || trace_hull( player.pev.origin, human_hull, 1024, vec_destination ) )
                {
                    g_EntityFuncs.SetOrigin( self, vec_destination );

                    #if SERVER
                        m_Logger.info( "Got candidate {} to summon", { player.pev.netname } );
                    #endif

                    auto vanisher = create_vanisher();

                    /*
                    * I've 1:1 scripted.cpp in the HLSDK but nope.
                    * Seems sven cum has some hacky stuff going on so i made this stupid entity spawn.
                    */

                    dictionary kv_pair;
                    kv_pair[ "targetname" ] = "npc_vanisher_sequence";
                    kv_pair[ "killtarget" ] = "npc_vanisher_sequence";
                    kv_pair[ "target" ] = "npc_vanisher_effect";
                    kv_pair[ "m_iszEntity" ] = "npc_vanisher";
                    kv_pair[ "m_iszPlay" ] = "ventclimb";
                    kv_pair[ "m_iszIdle" ] = "ventclimbidle";
                    kv_pair[ "m_flRadius" ] = "512";
                    kv_pair[ "m_fMoveTo" ] = "4";
                    kv_pair[ "spawnflags" ] = "96"; // ( verride AI | No Interruptions )

                    auto CineAI = g_EntityFuncs.CreateEntity( "scripted_sequence", kv_pair, true );

                    TraceResult tr;
                    g_Utility.TraceLine( vanisher.pev.origin + Vector( 0, 0, 90 ), vanisher.pev.origin + Vector( 0, 0, -90 ), ignore_monsters, vanisher.edict(), tr );

                    auto effects = g_EntityFuncs.Create( "_vanisher_effects_", tr.vecEndPos, g_vecZero, false, self.edict() );
                    effects.pev.skin = 1;
                    effects.pev.targetname = "npc_vanisher_effect";

                    g_EntityFuncs.SetOrigin( CineAI, tr.vecEndPos );

                    FireTargets( "npc_vanisher_sequence", self, self, USE_ON, 0, 1.4f );

                    pev.nextthink = g_Engine.time + 3.4f;
                    SetThink( ThinkFunction( this.state_stalk ) );

                    auto direction = ( player.pev.origin - vanisher.pev.origin );
                    direction.z = 0;
                    g_EngineFuncs.VecToAngles( direction, vanisher.pev.angles );

                    g_EntityFuncs.SetOrigin( vanisher, tr.vecEndPos - Vector( 0, 0, 100 ) );
                    vanisher.PushEnemy( player, player.pev.origin );
                }
            }
        }

        void state_stalk()
        {
            pev.nextthink = g_Engine.time + 0.1f;

            if( !shouldtoggle() )
            {
                SetThink( ThinkFunction( this.state_retire ) );
                return;
            }

            auto vanisher = m_hvanisher;

            vanisher.pev.framerate = Math.max( 1.0f, Math.min( m_maxspeed, m_maxspeed - ( ( vanisher.pev.health / m_health ) * ( m_maxspeed - 1.0f ) ) ) );

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
                }
                else
                {
                    vanisher.pev.frags = m_frags;
                    vanisher.ClearEnemyList();
                }
            }
            else if( !vanisher.m_hEnemy.IsValid() || vanisher.m_hEnemy.GetEntity() is null )
            {
                auto player = nearby_player();

                if( player !is null )
                {
                    #if SERVER
                        m_Logger.trace( "Lost sight of player enemy. Getting new player {}", { player.pev.netname } );
                    #endif

                    vanisher.PushEnemy( player, player.pev.origin );
                }
                else
                {
                    SetThink( ThinkFunction( this.state_retire ) );
                }
            }
            else if( !vanisher.m_hEnemy.GetEntity().FVisible( vanisher, false ) )
            {
                vanisher.pev.frags--; // frags defines it's stand time
            }
        }

        void state_retire()
        {
            auto vanisher = m_hvanisher;

            dictionary kv_pair;
            kv_pair[ "killtarget" ] = "npc_vanisher";
            kv_pair[ "targetname" ] = "npc_vanisher";
            kv_pair[ "target" ] = "npc_vanisher_effect";
            kv_pair[ "m_iszEntity" ] = "npc_vanisher";
            kv_pair[ "m_iszPlay" ] = "ventclimbdown";
            kv_pair[ "m_iszIdle" ] = "idle";
            kv_pair[ "m_flRadius" ] = "512";
            kv_pair[ "m_fMoveTo" ] = "1";
            kv_pair[ "spawnflags" ] = "96"; // ( verride AI | No Interruptions )

            auto CineAI = g_EntityFuncs.CreateEntity( "scripted_sequence", kv_pair, true );

            TraceResult tr;
            g_Utility.TraceLine( vanisher.pev.origin + Vector( 0, 0, 90 ), vanisher.pev.origin + Vector( 0, 0, -90 ), ignore_monsters, vanisher.edict(), tr );

            auto effects = g_EntityFuncs.Create( "_vanisher_effects_", tr.vecEndPos, g_vecZero, false, self.edict() );
            effects.pev.targetname = "npc_vanisher_effect";

            g_EntityFuncs.SetOrigin( CineAI, tr.vecEndPos );
            CineAI.pev.angles = vanisher.pev.angles;

            FireTargets( "npc_vanisher", self, self, USE_ON, 0, 1.4 );

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

            SetThink( ThinkFunction( this.state_emerge ) );
        }
    }
}
