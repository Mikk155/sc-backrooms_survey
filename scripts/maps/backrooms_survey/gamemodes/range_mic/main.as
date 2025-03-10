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

namespace range_mic
{
    const int RANGE = 500;

    void on_playerthink( CHookModule@ pHookInfo )
    {
        if( pHookInfo.player !is null )
        {
            for( int i = 1; i <= g_Engine.maxClients; i++ )
            {
                auto player = g_PlayerFuncs.FindPlayerByIndex( i );

                if( player !is null && player !is pHookInfo.player )
                {
                    bool in_range = !( ( player.pev.origin - pHookInfo.player.pev.origin ).Length() < RANGE );

                    g_EngineFuncs.Voice_SetClientListening( player.entindex(), pHookInfo.player.entindex(), !in_range );
                }
            }
        }
    }
}
