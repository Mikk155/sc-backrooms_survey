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

namespace vanisher
{
    class CVanisherTargets : ScriptBaseEntity, CToggleState
    {
        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
        {
            entity_state( use_type );
        }
    }
}