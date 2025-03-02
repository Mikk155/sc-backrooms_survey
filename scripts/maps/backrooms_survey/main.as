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

#include "entities/CWeapomCamera"
#include "entities/CTriggerInformation"

void MapInit()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "CTriggerInformation", "trigger_information" );

    g_CustomEntityFuncs.RegisterCustomEntity( "CWeapomCamera", "weapon_camera" );
    g_ItemRegistry.RegisterWeapon( "weapon_camera", "backgrooms/", String::EMPTY_STRING, "357", String::EMPTY_STRING, "ammo_357" );

    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @on_playerspawn );
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
