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

#include "../../utils/CRendering"
#include "../../utils/hud_message"
#include "../../utils/menu"

#include "CEnvironmentInformation"
#include "CCameraRender"
#include "CWeaponCamera"

namespace camera
{
    #if SERVER
        CLogger@ m_Logger = CLogger( "Camera" );
    #endif

    void On_MapPrecache( CHookModule@ pHookInfo )
    {
        g_Game .PrecacheModel( "sprites/glow01.spr" );

        custom_precache( "sound/cof/guns/camera/photo.ogg" );
        custom_precache( "sound/cof/guns/camera/charge.ogg" );
        custom_precache( "sound/cof/guns/camera/lever.ogg" );

        custom_precache( "models/cof/camera/vwm.mdl" );
        custom_precache( "models/cof/camera/wld.mdl" );

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
        CoFCAMERA_IDLE = 0,
        CoFCAMERA_DRAW_FIRST,
        CoFCAMERA_HOLSTER,
        CoFCAMERA_SHOOT,
        CoFCAMERA_FIDGET1,
        CoFCAMERA_JUMP_TO,
        CoFCAMERA_JUMP_FROM,
        CoFCAMERA_DRAW,
        CoFCAMERA_FIDGET2,
        CoFCAMERA_FIDGET3,
        CoFCAMERA_SPRINT_TO,
        CoFCAMERA_SPRINT_IDLE,
        CoFCAMERA_SPRINT_FROM,
        CoFCAMERA_MELEE 
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
