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

#include "../../baseclass/CFireTargets"

#if SERVER
    #include "../../utils/CLogger"
#endif

#include "CEnvFog"

namespace fog
{
    const int DEFAUL_START_LEVEL = 3000;
    const int DEFAUL_END_LEVEL = 5000;

    #if SERVER
        CLogger@ m_Logger = CLogger( "Fog Entity" );
    #endif

    array<int> entities(g_Engine.maxClients);

    void On_MapInit( CHookModule@ pHookInfo )
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "fog::CEnvFog", "env_fog_custom" );
    }

    enum fog_state
    {
        disabled = 0,
        enabling,
        enabled,
        disabling
    };

    enum fog_t
    {
        state = 0,
        red,
        green,
        blue,
        start,
        end
    }

    void On_MapThink( CHookModule@ pHookInfo )
    {
        for( uint ui = 0; ui < entities.length(); ui++ )
        {
            auto player = g_PlayerFuncs.FindPlayerByIndex( ui + 1 );

            if( player is null )
            {
                entities[ui] = 0;
                continue;
            }

            auto user_data = player.GetUserData();

            fog_state state = fog_state( user_data[ "env_fog_custom_state" ] );

            // Fog entity
            auto entity = ( entities[ui] == 0 ? null : g_EntityFuncs.Instance( entities[ui] ) );

            array<int>@ fog_details = array<int>( user_data[ "env_fog_custom_values" ] );

            // Define in case is the first time.
            if( fog_details is null || fog_details.length() < 6 )
            {
                fog_details = { 0, 0, 0, 0, 0, 0 };
                user_data[ "env_fog_custom_state" ] = state = fog_state::disabled;
            }

            // If is null clear and set as disabling.
            if( entity is null )
            {
                entities[ui] = 0;

                user_data[ "env_fog_custom_state" ] = state = fog_state::disabling;
            }
            else if( state == fog_state::disabled && entity.pev.classname == "env_fog_custom" ) // Fog disabled but we got a entity so start enabling.
            {
                auto fog = cast<CEnvFog@>( CastToScriptClass( entity ) );

                fog_details[fog_t::state] = 1;
                fog_details[fog_t::red] = fog.m_color.r;
                fog_details[fog_t::green] = fog.m_color.g;
                fog_details[fog_t::blue] = fog.m_color.b;
                fog_details[fog_t::start] = DEFAUL_START_LEVEL;
                fog_details[fog_t::end] = DEFAUL_END_LEVEL;

                user_data[ "env_fog_custom_state" ] = state = fog_state::enabling;
            }

            // It's already on it's peak. we do not need to update anymore.
            if( state == fog_state::enabled || state == fog_state::disabled )
                continue;

            bool should_update;

            if( state == fog_state::enabling )
            {
                if( entity.pev.classname != "env_fog_custom" ) // Has this been disabled during running?
                {
                    user_data[ "env_fog_custom_state" ] = state = fog_state::disabling;
                    continue;
                }

                auto fog = cast<CEnvFog@>( CastToScriptClass( entity ) );

                int c_start = fog_details[fog_t::start];

                if( c_start > fog.m_distance_start )
                {
                    should_update = true;
                    fog_details[fog_t::start] = Math.clamp( fog.m_distance_start, DEFAUL_START_LEVEL, c_start - ( DEFAUL_START_LEVEL / 100 ) );
                }

                int c_end = fog_details[fog_t::end];

                if( c_end > fog.m_distance_end )
                {
                    should_update = true;
                    fog_details[fog_t::end] = Math.clamp( fog.m_distance_end, DEFAUL_END_LEVEL, c_end - ( DEFAUL_END_LEVEL / 100 ) );
                }

                // Are we done yet?
                if( fog_details[fog_t::start] == fog.m_distance_start && fog_details[fog_t::end] == fog.m_distance_end )
                {
                    user_data[ "env_fog_custom_state" ] = fog_state::enabled;
                }
            }
            else if( state == fog_state::disabling )
            {
                if( entity !is null && entity.pev.classname == "env_fog_custom" ) // Has this been enabled during running?
                {
                    user_data[ "env_fog_custom_state" ] = state = fog_state::disabled;
                    continue;
                }

                int c_start = fog_details[fog_t::start];

                if( c_start < DEFAUL_START_LEVEL )
                {
                    should_update = true;
                    fog_details[fog_t::start] = Math.clamp( c_start, DEFAUL_START_LEVEL, c_start + ( DEFAUL_START_LEVEL / 100 ) );
                }

                int c_end = fog_details[fog_t::end];

                if( c_end < DEFAUL_END_LEVEL )
                {
                    should_update = true;
                    fog_details[fog_t::end] = Math.clamp( c_end, DEFAUL_END_LEVEL, c_end + ( DEFAUL_END_LEVEL / 100 ) );
                }

                // Are we done yet?
                if( fog_details[fog_t::start] == DEFAUL_START_LEVEL && fog_details[fog_t::end] == DEFAUL_END_LEVEL )
                {
                    fog_details[fog_t::state] = 0;

                    user_data[ "env_fog_custom_state" ] = fog_state::disabled;
                }
            }

            if( should_update )
            {
                #if SERVER
                    m_Logger.trace( "State: {} start: {} end: {} RGB: {} {} {} player:", {
                        fog_details[fog_t::state] == 1 ? "ON" : "OFF",
                        fog_details[fog_t::start],
                        fog_details[fog_t::end],
                        fog_details[fog_t::red],
                        fog_details[fog_t::green],
                        fog_details[fog_t::blue],
                        player.pev.netname
                    } );
                #endif

                user_data[ "env_fog_custom_values" ] = fog_details;

                // Are we using the camera's night vision?
                if( bool( user_data[ "camera_nightvision" ] ) )
                    continue;

                NetworkMessage fog( MSG_ONE_UNRELIABLE, NetworkMessages::Fog, player.edict() );
                    fog.WriteShort(0);
                    fog.WriteByte( fog_details[fog_t::state] );
                    fog.WriteCoord(0);
                    fog.WriteCoord(0);
                    fog.WriteCoord(0);
                    fog.WriteShort(0);
                    fog.WriteByte( fog_details[fog_t::red] );
                    fog.WriteByte( fog_details[fog_t::green] );
                    fog.WriteByte( fog_details[fog_t::blue] );
                    fog.WriteShort( fog_details[fog_t::start] );
                    fog.WriteShort( fog_details[fog_t::end] );
                fog.End();
            }
        }
    }
}
