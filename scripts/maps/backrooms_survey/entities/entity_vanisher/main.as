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

#include "../../baseclass/CFireTargets"
#include "../../baseclass/CToggleState"

#if SERVER
    #include "../../utils/CLogger"
#endif

#include "../../utils/trace_hull"

#include "CVanisherEffects"

#include "CVanisherTargets"

#include "CNPCVanisher"

namespace vanisher
{
    #if SERVER
        CLogger@ m_Logger = CLogger( "NPC Vanisher" );
    #endif

    void On_MapInit( CHookModule@ pHookInfo )
    {
        custom_precache( "sprites/brp/vanisher.spr" );
        custom_precache( "models/brp/npcs/vanisher_puddle.mdl" );
        g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CNPCVanisher", "npc_vanisher" );
        g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CVanisherEffects", "_vanisher_effects_" );
        g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CVanisherTargets", "info_vanisher_destination" );
    }

    enum vanisher_anims
    {
        idle = 0,
        walk,
        attack,
        attack2,
        submerge,
        sub_idle,
        emerge,
        die
    };

    CBaseMonster@ vanisher_npc()
    {
        auto vanisher = g_EntityFuncs.FindEntityByTargetname( null, "npc_vanisher" );

        if( vanisher !is null )
        {
            return cast<CBaseMonster@>( vanisher );
        }

        return null;
    }

    CBasePlayer@ nearby_player()
    {
        CBasePlayer@ near_entity = null;

        auto vanisher = vanisher_npc();

        if( vanisher !is null )
        {
            for( int i = 0; i <= g_Engine.maxClients; i++ )
            {
                auto candidate = g_PlayerFuncs.FindPlayerByIndex( i );

                // -TODO commented due to lack of FGetNodeRoute
//                if( candidate !is null && candidate.IsAlive() && ( candidate.pev.flags & FL_NOTARGET ) == 0 && vanisher.FGetNodeRoute( candidate.pev.origin ) && ( near_entity is null
                if( candidate !is null && candidate.IsAlive() && ( candidate.pev.flags & FL_NOTARGET ) == 0 && ( near_entity is null
                || ( candidate.pev.origin - vanisher.pev.origin ).Length() < ( near_entity.pev.origin - vanisher.pev.origin ).Length() ) )
                {
                    @near_entity = candidate;
                }
            }
        }

        return near_entity;
    }

    void on_playertakedamage( CHookModule@ pHookInfo )
    {
        if( pHookInfo.attacker !is null && pHookInfo.victim !is null && pHookInfo.attacker.pev.targetname == "npc_vanisher" )
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

            teleports[ Math.RandomLong( 0, size - 1 ) ].teleport( cast<CBasePlayer@>( pHookInfo.victim ) );

            auto vanisher = cast<CBaseMonster@>( pHookInfo.attacker );

            vanisher.ClearEnemyList();

            auto enemy = nearby_player();

            if( enemy !is null )
            {
                vanisher.PushEnemy( enemy, enemy.pev.origin );
            }

            pHookInfo.damage = 0;
            pHookInfo.stop = true;
        }
    }
}
