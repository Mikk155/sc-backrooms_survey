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

#include "utils/CLogger"

#include "utils"

#include "entities/CEnvironmentInformation"

#include "npcs/vanisher/main"

#include "weapons/CWeaponCamera"

void MapInit()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvironmentInformation", "env_info" );

    g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CNPCVanisher", "npc_vanisher" );
    g_CustomEntityFuncs.RegisterCustomEntity( "vanisher::CVanisherTargets", "info_vanisher_destination" );

    g_CustomEntityFuncs.RegisterCustomEntity( "CWeaponCamera", "weapon_camera" );
    g_ItemRegistry.RegisterWeapon( "weapon_camera", "backgrooms/", "357", "", "ammo_357" );

    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @on_playerspawn );
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @on_playertakedamage );

#if SERVER
    g_Game .PrecacheModel( "sprites/glow01.spr" );
#endif

    // Initialize player-basis arrays
    for( int i = 0; i < g_Engine.maxClients; i++ ) {
        trigger_cameras.insertLast( EHandle(null) );
        render_individuals.insertLast( EHandle(null) );
        menus.insertLast( null );
    }

    hud_msg.x = -1;
    hud_msg.r1 = 255;
    hud_msg.g1 = hud_msg.b1 = hud_msg.a1 = hud_msg.r2 = hud_msg.g2 = hud_msg.b2 = hud_msg.a2 = hud_msg.effect = 0;
    hud_msg.fadeinTime = hud_msg.fxTime = 0.0f;
    hud_msg.fadeoutTime = 0.25;
    hud_msg.holdTime = 2;
    hud_msg.channel = 4;
    hud_msg.y = 0.90;
}

void MapStart()
{
}

void MapActivate()
{
}

HookReturnCode on_playerspawn( CBasePlayer@ player )
{
    if( player is null )
        return HOOK_CONTINUE;

    if( player.HasNamedPlayerItem( "weapon_camera" ) is null )
    {
        player.GiveNamedItem( "weapon_camera", 0, 5 );
    }

    return HOOK_CONTINUE;
}

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
                cast<vanisher::CNPCVanisher@>( CastToScriptClass( vanisher ) ).attack( victim );
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