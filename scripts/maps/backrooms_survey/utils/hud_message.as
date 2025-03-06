/*
    This is been done just for lazy cleanup.
*/

namespace hud_message
{
    HUDTextParams param;

    void print( CBasePlayer@ player, const string& in message, const RGBA &in color = RGBA_WHITE )
    {
        param.r1 = param.r2 = color.r;
        param.g1 = param.g2 = color.g;
        param.b1 = param.b2 = color.b;
        param.a1 = param.a2 = color.a;

        if( player !is null )
        {
            g_PlayerFuncs.HudMessage( player, param, message );
        }

        param.fxTime = 0.0f;
        param.fadeinTime = 0.0f;
        param.holdTime = 2;
        param.fadeoutTime = 0.25;

        param.channel = 4;

        param.x = -1;
        param.y = 0.90;

        param.effect = 0;
    }

    void print( CBaseEntity@ player, const string& in message, const RGBA &in color = RGBA_WHITE )
    {
        if( player !is null && player.IsPlayer() )
            print( cast<CBasePlayer@>( player ), message, color );
    }
}
