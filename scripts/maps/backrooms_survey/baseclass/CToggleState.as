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

enum CToggleState_t
{
    START_OFF = 1
};

mixin class CToggleState
{
    bool shouldtoggle( int use_type = -1 )
    {
        switch( use_type )
        {
            case USE_ON:
            {
                pev.spawnflags &= ~CToggleState_t::START_OFF;
                break;
            }
            case USE_OFF:
            {
                pev.spawnflags |= CToggleState_t::START_OFF;
                break;
            }
            case USE_SET:
            case USE_TOGGLE:
            {
                if( ( pev.spawnflags & CToggleState_t::START_OFF ) != 0 )
                {
                    pev.spawnflags &= ~CToggleState_t::START_OFF;
                }
                else
                {
                    pev.spawnflags |= CToggleState_t::START_OFF;
                }
                break;
            }
            /*
            default:
            WARNING: Angelscript: .../ctogglestate.as (61, 9) : Unreachable code XD
            */
            case -1:
            {
                return ( ( pev.spawnflags & CToggleState_t::START_OFF ) == 0 );
            }
        }

        #if SERVER
            g_Logger.trace( "Entity {}::{}::{} is been {}.", { self.entindex(), self.pev.classname, self.pev.targetname, ( ( pev.spawnflags & CToggleState_t::START_OFF ) == 0 ? "enabled" : "disabled" ) } );
        #endif

        return ( ( pev.spawnflags & CToggleState_t::START_OFF ) == 0 );
    }
}
