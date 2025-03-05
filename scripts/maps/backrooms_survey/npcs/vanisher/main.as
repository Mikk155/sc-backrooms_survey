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

#include "CVanisherTargets"
#include "CNPCVanisher"

namespace vanisher
{
#if SERVER
    CLogger@ m_Logger = CLogger( "NPC Vanisher" );
#endif

    enum vanisher_state
    {
        // Waiting for cooldown end.
        on_wait = 0,
        // summoned to a player. charging to said player.
        on_charging,
        // Touched the player or lose sight of the player.
        on_search,
        // Search ended. no new targets. leave to ground and wait.
        on_leave
    };

    enum vanisher_anims
    {
        idle = 0,
        walk,
        attack,
        attack2,
        submerge,
        sub_idle,
        emerge,
        die
    };
}
