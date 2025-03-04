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

mixin class CToggleState
{
    /*
    *   Return whatever a entity is enabled
    *   If USE_TYPE != USE_SET then we'll set the state.
    */
    bool entity_state( USE_TYPE use_type = USE_SET )
    {
        switch( use_type )
        {
            case USE_ON:
            {
#if SERVER
                g_Logger.trace( "Entity {}::{}::{} is been {}.", { self.entindex(), self.pev.classname, self.pev.targetname, "enabled" } );
#endif
                pev.spawnflags &= ~1;
                return true;
            }
            case USE_OFF:
            {
#if SERVER
                g_Logger.trace( "Entity {}::{}::{} is been {}.", { self.entindex(), self.pev.classname, self.pev.targetname, "disabled" } );
#endif
                pev.spawnflags |= 1;
                return false;
            }
            case USE_TOGGLE:
            {
                if( ( pev.spawnflags & 1 ) != 0 )
                {
#if SERVER
                    g_Logger.trace( "Entity {}::{}::{} is been {}.", { self.entindex(), self.pev.classname, self.pev.targetname, "disabled" } );
#endif
                    pev.spawnflags |= 1;
                    return false;
                }
                else
                {
#if SERVER
                    g_Logger.trace( "Entity {}::{}::{} is been {}.", { self.entindex(), self.pev.classname, self.pev.targetname, "enabled" } );
#endif
                    pev.spawnflags &= ~1;
                    return true;
                }
            }
            default:
            {
                return ( ( pev.spawnflags & 1 ) == 0 );
            }
        }
    }
}
