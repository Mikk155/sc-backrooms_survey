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
    class CNPCVanisher : ScriptBaseEntity, CToggleState
    {
        // Current state
        vanisher_state m_state = on_wait;

        // Time until reach 0 and summon to a random player.
        float m_next_summon;

        // Time until starts going on ground.
        float m_next_retire;

        // Time until it's retired.
        float m_has_retired;

        int m_min_cooldown = 1200;
        int m_max_cooldown = 6000;
        int m_retire_time = 10;

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
                m_next_summon = 0;
                m_state = vanisher_state::on_wait;

                auto vanisher = m_hvanisher;

                if( vanisher !is null )
                {
#if SERVER
                    m_Logger.warn( "Turned off NPC controller but the vanisher npc reference exists. Removing..." );
#endif
                    // -TODO Should we play submerge animation?
                    g_EntityFuncs.Remove( vanisher );
                }
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
            return false;
        }

        CBaseMonster@ create_vanisher()
        {
            CBaseEntity@ entity = null;

            for( int i = 0; entity is null and i <= 3; i++ ) // i recall sometimes AS randomly fails so try again if needed.
                @entity = g_EntityFuncs.Create( "monster_zombie", pev.origin, pev.angles, true, self.edict() );

            g_EntityFuncs.DispatchKeyValue( entity.edict(), "freeroam", "2" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "health", "1000" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "bloodcolor", "1" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "soundlist", "backrooms_survey/vanisher.gsr" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "model", "models/backrooms_survey/npcs/vanisher.mdl" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "displayname", "Vanisher" );
            g_EntityFuncs.DispatchKeyValue( entity.edict(), "targetname", "npc_vanisher" );

            g_EntityFuncs.DispatchSpawn( entity.edict() );

            g_EntityFuncs.SetOrigin( entity, self.pev.origin );

            @self.pev.owner = entity.edict();

            return m_hvanisher;
        }

        void Spawn()
        {
            // This precaches the gsr and model then removes the entity.
            g_EntityFuncs.Remove( create_vanisher() );

            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );

            SetThink( ThinkFunction( this.think ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        void think()
        {
            pev.nextthink = g_Engine.time + 0.1f;

            if( !entity_state() )
                return;

            switch( m_state )
            {
                case vanisher_state::on_wait:
                {
                    if(  m_next_summon > g_Engine.time )
                        return;

#if SERVER
                    m_Logger.trace( "Time to summon! Enumerating player candidates:" );
#endif

                    array<int> players = {};

                    for( int i = 0; i <= g_Engine.maxClients; i++ )
                    {
                        auto candidate = g_PlayerFuncs.FindPlayerByIndex( i );

                        if( candidate !is null
                        and candidate.IsConnected()
                        and candidate.IsAlive()
                        ) {
#if SERVER
                            m_Logger.trace( candidate.pev.netname );
#endif
                        }
                    }

                    // -TODO Get a random player with special logic handling to not include everyone in "safe" parts of the map.
                    auto player = g_EntityFuncs.FindEntityByClassname( null, "player" );

                    if( player !is null )
                    {
                        auto vanisher = create_vanisher();

                        if( vanisher !is null )
                        {
#if SERVER
                            m_Logger.trace( "Got candidate {} to summon in", { player.pev.netname } );
#endif
                            // TEST
                            if( true ) {
                                m_state = vanisher_state::on_search;
                                m_next_retire = g_Engine.time + m_retire_time;
                                return;
                            }

                            vanisher.m_hEnemy = EHandle( player );
                        }

                        m_state = vanisher_state::on_charging;
                    }

                    break;
                }
                case vanisher_state::on_charging:
                {
                    auto vanisher = m_hvanisher;

                    if( vanisher is null )
                    {
                        m_next_summon = 0;
                        m_state = vanisher_state::on_wait;
                        return;
                    }

                    if( !vanisher.m_hEnemy.IsValid() || vanisher.m_hEnemy.GetEntity() is null )
                    {
#if SERVER
                        m_Logger.trace( "Lost sight of player enemy. retiring in {}", { m_retire_time } );
#endif
                        vanisher.SetState( MONSTERSTATE_IDLE ); // So it roams a bit.
                        m_state = vanisher_state::on_search;
                        m_next_retire = g_Engine.time + m_retire_time;
                    }
                    else
                    {
                        // -TODO Make the zombie lose m_hEnemy
                        vanisher.m_hEnemy = EHandle( null );
                    }

                    break;
                }
                case vanisher_state::on_search:
                {
                    auto vanisher = m_hvanisher;

                    if( vanisher is null )
                    {
                        m_next_summon = 0;
                        m_state = vanisher_state::on_wait;
                        return;
                    }

                    if( g_Engine.time > m_next_retire )
                    {
                        TraceResult tr;
                        g_Utility.TraceLine( vanisher.pev.origin + Vector( 0, 0, 90 ), vanisher.pev.origin + Vector( 0, 0, -90 ), ignore_monsters, vanisher.edict(), tr );
                        g_Utility.DecalTrace( tr, DECAL_SCORCH1 );

                        vanisher.SetState( MONSTERSTATE_PLAYDEAD );
                        vanisher.m_scriptState = SCRIPT_WAIT;
                        vanisher.pev.sequence = vanisher_sequences::submerge;
                        vanisher.pev.spawnflags |= 32; // SF_SCRIPT_NOINTERRUPT

                        m_state = vanisher_state::on_leave;
                    }
                    else if( vanisher.m_hEnemy.IsValid() && vanisher.m_hEnemy.GetEntity() !is null )
                    {
                        m_state = vanisher_state::on_charging;
#if SERVER
                        m_Logger.trace( "Found a new enemy {}. restoring to previous state", { vanisher.m_hEnemy.GetEntity().pev.netname } );
#endif
                    }
                    break;
                }
                case vanisher_state::on_leave:
                {
                    auto vanisher = m_hvanisher;

                    if( vanisher is null )
                    {
                        // Set next summon time.
                        m_next_summon = g_Engine.time + float(
                            m_min_cooldown + 
                                ( m_max_cooldown - m_min_cooldown ) *
                                    ( g_Engine.maxClients - g_PlayerFuncs.GetNumPlayers() ) /
                                        ( g_Engine.maxClients - 1 )
                        );
#if SERVER
                        m_Logger.trace( "Vanisher npc gone. summoning again in {}", { m_next_summon } );
#endif
                        m_state = vanisher_state::on_wait;
                    }
                    else
                    {
                        vanisher.StudioFrameAdvance();
                        /*
                        vanisher.UpdateOnRemove();
                        vanisher.pev.flags |= FL_KILLME;
                        vanisher.pev.targetname = 0;
                        @self.pev.owner = null;
                        */
                    }

                    break;
                }
            }
        }

        void attack( CBasePlayer@ player )
        {
            array<CVanisherTargets@> teleports = {};

            CBaseEntity@ teleport = null;

            while( ( @teleport = g_EntityFuncs.FindEntityByTargetname( teleport, "info_vanisher_destination" ) ) !is null )
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
