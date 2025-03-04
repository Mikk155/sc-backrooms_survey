#include "utils/CFireTarget"
#include "utils/CToggleState"

// Array of env_info entities
array<EHandle> information_entities = {};

// Array of CTextMenu for each player.
array<CTextMenu@> menus = {};

// Array of trigger_camera for each player
array<EHandle> trigger_cameras = {};

// Array of env_render_individual for each player
array<EHandle> render_individuals = {};

void apply_rendering( CBasePlayer@ player, const string &in target, bool enable, int rendermode = -1, float renderamt = -1, int renderfx = -1, Vector rendercolor = Vector( -1, -1, -1 ) )
{
    if( player is null )
        return;

    auto handle = render_individuals[ player.entindex() - 1 ];

    if( handle.IsValid() && handle.GetEntity() !is null )
    {
        auto render = handle.GetEntity();

        if( !enable )
        {
            render.Use( player, player, USE_OFF, 0 );
        }
        else
        {
            render.pev.target = target;

            render.pev.spawnflags = 64; // Affect Activator (ignore netname)

            if( int(renderamt) == -1 ) {
                render.pev.spawnflags |= 1;
            } else {
                render.pev.renderamt = renderamt;
            }
            if( renderfx == -1 ) {
                render.pev.spawnflags |= 2;
            } else {
                render.pev.renderfx = renderfx;
            }
            if( rendermode == -1 ) {
                render.pev.spawnflags |= 4;
            } else {
                render.pev.rendermode = rendermode;
            }
            if( rendercolor.y == -1 && rendercolor.x == -1 && rendercolor.z == -1 ) {
                render.pev.spawnflags |= 8;
            } else {
                render.pev.rendercolor = rendercolor;
            }

            render.Use( player, player, USE_ON, 0 );
        }
        return;
    }

    auto render = g_EntityFuncs.Create( "env_render_individual", g_vecZero, g_vecZero, false, player.edict() );

    if( render !is null )
    {
        string name;
        snprintf( name, "%1_render", player.entindex() );
        render.pev.targetname = name;
        render.pev.spawnflags = 64; // Affect Activator (ignore netname)

        render_individuals[ player.entindex() - 1 ] = EHandle( render );
    }

    apply_rendering( player, target, enable, rendermode, renderamt, renderfx, rendercolor );
}

void remove_rendering( int index_player, string target )
{
    auto player = g_PlayerFuncs.FindPlayerByIndex( index_player );

    if( player !is null )
        apply_rendering( player, target, false );
}

void apply_rendering( CBasePlayer@ player, CBaseEntity@ target, bool enable, int rendermode = -1, float renderamt = -1, int renderfx = -1, Vector rendercolor = Vector( -1, -1, -1 ) )
{
    if( target !is null )
        apply_rendering( player, target.pev.targetname, enable, rendermode, renderamt, renderfx, rendercolor );
}

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
