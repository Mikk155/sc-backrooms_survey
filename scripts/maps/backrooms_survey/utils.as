#include "utils/CFireTarget"
#if SERVER
#include "utils/CLogger"
#endif
#include "utils/CRendering"
#include "utils/CToggleState"

// Array of env_info entities
array<EHandle> information_entities = {};

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
        camera.pev.spawnflags |= 4; // Freeze Player
        camera.pev.spawnflags |= 256; // Player Invulnerable

        trigger_cameras[ index - 1 ] = EHandle( camera );
        return @camera;
    }

    return null;
}

const float M_PI = ( 180.0 / 3.14159265358979323846 );

// Global hud params
HUDTextParams hud_msg;

// Idk. schedules sucks.
class GlobalThink : ScriptBaseEntity
{
    void think()
    {
        MapThink();
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void Spawn()
    {
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;
        SetThink( ThinkFunction( this.think ) );
        pev.nextthink = g_Engine.time + 0.1f;
    }
}
