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

mixin class CFireTarget
{
    protected USE_TYPE m_usetype = USE_TOGGLE;
    protected float m_delay;

    bool CFireTarget( const string& in key, const string& in value )
    {
        if( key == "m_usetype" )
        {
            m_usetype = cast<USE_TYPE>( Math.clamp( USE_OFF, USE_KILL, atoi( value ) ) );
            return true;
        }
        else if( key == "m_delay" )
        {
            m_delay = atof( value );
            return true;
        }
        return false;
    }

    void FireTarget( CBaseEntity@ activator, CBaseEntity@ caller, const string&in target )
    {
        g_EntityFuncs.FireTargets( target, activator, caller is null ? self : caller, m_usetype, 0, m_delay );
    }

    void FireTarget( CBaseEntity@ activator, CBaseEntity@ caller )
    {
        FireTarget( activator, caller, pev.target );
    }
}
