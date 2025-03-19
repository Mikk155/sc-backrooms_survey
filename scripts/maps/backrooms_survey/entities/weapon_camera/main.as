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

#include "../../baseclass/CFireTargets"
#include "../../baseclass/CToggleState"

#include "../../utils/CRendering"
#include "../../utils/hud_message"
#include "../../utils/menu"

#include "CEnvironmentInformation"
#include "CCameraRender"
#include "CWeaponCamera"

namespace camera
{
    const float MAX_BATTERY_CAPACITY = 10000.0f;
    const int MAX_FOG_DISTANCE = 500;

    #if SERVER
        CLogger@ m_Logger = CLogger( "Camera" );
    #endif

    void On_MapPrecache( CHookModule@ pHookInfo )
    {
        g_Game .PrecacheModel( "sprites/glow01.spr" );

        custom_precache( "sound/brp/camera/photo.ogg" );

        g_Game.PrecacheGeneric( "sound/brp/camera/charge.ogg" );
	g_Game.PrecacheGeneric( "sound/brp/camera/lever.ogg" );
	g_Game.PrecacheGeneric( "sound/brp/camera/safe.ogg" );
	g_Game.PrecacheGeneric( "sound/brp/camera/tap.ogg" );
	g_Game.PrecacheGeneric( "sound/brp/camera/in1.ogg" );
	g_Game.PrecacheGeneric( "sound/brp/camera/out3.ogg" );

        custom_precache( "models/brp/v_camera.mdl" );

        custom_precache( "models/brp/w_camera.mdl" );

        custom_precache( "sprites/cof/wpn_sel01.spr" );

        g_Game.PrecacheGeneric( "sprites/brp/weapon_camera.txt" );
    }

    void On_MapInit( CHookModule@ pHookInfo )
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "camera::CEnvironmentInformation", "env_info" );
        g_CustomEntityFuncs.RegisterCustomEntity( "camera::CCameraRender", "env_camera_render" );
        g_CustomEntityFuncs.RegisterCustomEntity( "camera::CWeaponCamera", "weapon_camera" );
        g_ItemRegistry.RegisterWeapon( "weapon_camera", "brp", "357", "", "ammo_357" );
    }

    // Array of env_info entities
    array<int> information_entities = {};

    class CPicture
    {
        Vector position;
        Vector angles;
        int index;

        CPicture( Vector _position, Vector _angles, int _index )
        {
            position = _position;
            angles = _angles;
            index = _index;
        }
    }

    enum camera_anim
    {
        idle = 0,
        draw_first,
        holster,
        shoot,
        fidget1,
        jump_to,
        jump_from,
        draw,
        fidget2,
        fidget3,
        sprint_to,
        sprint_idle,
        sprint_from,
        melee,
        zoom_in,
        zoom_out,
        zoom_idle,
        reload
    };

    enum battery_bodygroup
    {
        zero_lines = 0,
        one_line,
        two_lines,
        three_lines,
        four_lines,
        group = 5,
//        animation = camera_anim::zoom_idle
        animation = 18
    };

    enum sprint_state
    {
        sprint_no = 0,
        sprint_start,
        sprint_loop,
        sprint_end
    };

    void on_playerspawn( CHookModule@ pHookInfo )
    {
        if( pHookInfo.player !is null && pHookInfo.player.HasNamedPlayerItem( "weapon_camera" ) is null )
        {
            pHookInfo.player.GiveNamedItem( "weapon_camera", 0, 5 );
        }
    }
}
