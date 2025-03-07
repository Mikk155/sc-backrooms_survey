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

#include "../../baseclass/CFireTarget"
#include "../../baseclass/CToggleState"

#if SERVER
#include "../../utils/CLogger"
#endif

#include "../../utils/trace_hull"

#include "CVanisherTargets"

#include "CNPCVanisher"

namespace vanisher
{
#if SERVER
    CLogger@ m_Logger = CLogger( "NPC Vanisher" );
#endif

    void On_MapInit( CHookModule@ pHookInfo )
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CNPCVanisher", "npc_vanisher" );
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

            // -TODO Update pHookInfo.attacker's enemy to a new player.

            pHookInfo.damage = 0;
            pHookInfo.stop = true;
        }
    }
}
