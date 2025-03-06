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

#if SERVER
#include "../../utils/CLogger"
#endif

#include "../../baseclass/CFireTarget"
#include "../../baseclass/CToggleState"

#include "CVanisherTargets"

#include "CNPCVanisher"

namespace vanisher
{
#if SERVER
    CLogger@ m_Logger = CLogger( "NPC Vanisher" );
#endif

    void On_MapInit()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CNPCVanisher", "npc_vanisher" );
        g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CVanisherTargets", "info_vanisher_destination" );

        g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @vanisher::on_playertakedamage );
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

    HookReturnCode on_playertakedamage( DamageInfo@ pDamageInfo )
    {
        auto victim = ( pDamageInfo.pVictim !is null ? cast<CBasePlayer@>( pDamageInfo.pVictim ) : null );
        auto attacker = ( pDamageInfo.pAttacker !is null ? pDamageInfo.pAttacker : pDamageInfo.pInflictor );
        auto inflictor = ( pDamageInfo.pInflictor !is null ? pDamageInfo.pInflictor : pDamageInfo.pAttacker );
        auto damage = pDamageInfo.flDamage;
        auto bits = pDamageInfo.bitsDamageType;

        if( victim is null )
            return HOOK_CONTINUE;

        if( attacker !is null )
        {
            if( attacker.pev.targetname == "npc_vanisher" )
            {
                auto vanisher = g_EntityFuncs.FindEntityByClassname( null, "npc_vanisher" );

                try
                {
                    cast<vanisher::CNPCVanisher@>( CastToScriptClass( attacker ) ).attack( victim );
                }
                catch
                {
                    g_EntityFuncs.Remove( vanisher );
                }

                pDamageInfo.flDamage = 0;
                return HOOK_CONTINUE;
            }
        }
        return HOOK_CONTINUE;
    }
}
