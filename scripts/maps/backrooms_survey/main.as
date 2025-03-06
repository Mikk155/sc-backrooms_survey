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

#include "Reflection"

namespace main
{
    void On_MapInit( CHookModule@ pHookInfo )
    {
        // Initialize player-basis arrays
        for( int i = 0; i < g_Engine.maxClients; i++ ) {
            trigger_cameras.insertLast( EHandle(null) );
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
}

// Global hud params
HUDTextParams hud_msg;

// Array of CTextMenu for each player.
array<CTextMenu@> menus = {};

// Array of trigger_camera for each player
array<EHandle> trigger_cameras = {};

/*
    Get a per-player camera.

    If it doesn't exists we'll create one.
*/
CBaseEntity@ get_camera( int index )
{
    auto handle = trigger_cameras[ index - 1 ];

    if( handle.IsValid() )
    {
        auto camera = handle.GetEntity();

        if( camera !is null )
        {
            return @camera;
        }
    }

    dictionary keyvalue_data;

    // Targets to trigger when a player starts or stops using a camera
//    keyvalue_data[ "m_iszTargetWhenPlayerStartsUsing" ] = "";
//    keyvalue_data[ "m_iszTargetWhenPlayerStopsUsing" ] = "";
// -TODO Maybe Raptor could use these?

    keyvalue_data[ "max_player_count" ] = "1";
    keyvalue_data[ "hud_health" ] = "1";
    keyvalue_data[ "hud_flashlight" ] = "1";
    keyvalue_data[ "hud_weapons" ] = "1";
/*
    keyvalue_data[ "mouse_action_0_0" ] = "255";
    keyvalue_data[ "mouse_action_0_1" ] = "255";
    keyvalue_data[ "mouse_action_1_0" ] = "255";
    keyvalue_data[ "mouse_action_1_1" ] = "255";
    keyvalue_data[ "mouse_action_2_0" ] = "255";
    keyvalue_data[ "mouse_action_2_1" ] = "255";
*/
    keyvalue_data[ "wait" ] = "10";

    auto camera = g_EntityFuncs.CreateEntity( "trigger_camera", keyvalue_data, true );

    if( camera !is null )
    {
        camera.pev.spawnflags |= 256; // Player Invulnerable

        trigger_cameras[ index - 1 ] = EHandle( camera );
        return @camera;
    }

    return null;
}

void custom_precache( const string& in filename )
{
    g_Game.PrecacheGeneric( filename );

    if( filename.EndsWith( ".spr" ) || filename.EndsWith( ".mdl" ) )
    {
        g_Game.PrecacheModel( filename );
    }
    else
    {
        g_SoundSystem.PrecacheSound( filename.SubString( 6 ) );
    }
}