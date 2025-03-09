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

#include "../utils/FireTargets"

mixin class CFireTargets
{
    USE_TYPE m_usetype = USE_TOGGLE;
    float m_delay;
    string m_killtarget;

    bool CFireTargets( const string& in key, const string& in value )
    {
        if( key == "m_usetype" )
        {
            m_usetype = USE_TYPE( Math.clamp( USE_OFF, USE_KILL, atoi( value ) ) );
            return true;
        }
        else if( key == "m_delay" )
        {
            m_delay = atof( value );
            return true;
        }
        else if( key == "m_killtarget" )
        {
            m_killtarget = value;
            return true;
        }
        return false;
    }
}
