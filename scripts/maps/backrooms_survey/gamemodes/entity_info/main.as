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

#include "../../utils/hud_message"

namespace entity_info
{
    void on_playerthink( CHookModule@ pHookInfo )
    {
        if( pHookInfo.player !is null )
        {
            TraceResult tr;

            auto vec_start = pHookInfo.player.pev.origin + pHookInfo.player.pev.view_ofs;

            g_Utility.TraceLine( vec_start, vec_start + g_Engine.v_forward * 1024, dont_ignore_monsters, dont_ignore_glass, pHookInfo.player.edict(), tr );

            if( g_EntityFuncs.IsValidEntity( tr.pHit ) )
            {
                auto entity = g_EntityFuncs.Instance( tr.pHit );

                if( entity !is null )
                {
                    string message;

                    auto ckv = entity.GetCustomKeyvalues();

                    if( ckv.HasKeyvalue( "$s_entity_info" ) )
                    {
                        snprintf( message, ckv.GetKeyvalue( "$s_entity_info" ).GetString() );
                    }
                    else if( entity.IsMonster() )
                    {
                        auto monster = cast<CBaseMonster@>( entity );

                        if( monster !is null )
                        {
                            snprintf( message, "Name: %1\nHealth: %2", ( monster.IsPlayer() ? monster.pev.netname : monster.m_FormattedName ), int(monster.pev.health) );
                        }
                    }

                    if( message != String::EMPTY_STRING )
                    {
                        hud_message::param.channel = 3;
                        hud_message::param.holdTime = 0.2f;
                        hud_message::param.x = 0.0;
                        hud_message::param.y = 0.65;
                        hud_message::print( pHookInfo.player, message, RGBA( 150, 255, 0 ) );
                    }
                }
            }
        }
    }
}
