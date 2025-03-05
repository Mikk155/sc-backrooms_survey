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
    protected string m_killtarget;

    bool CFireTarget( const string& in key, const string& in value )
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

    void FireTarget( const string&in target, CBaseEntity@ activator, CBaseEntity@ caller = null )
    {
        if( m_killtarget != String::EMPTY_STRING )
        {
            CBaseEntity@ entity = null;

            while( ( @entity = g_EntityFuncs.FindEntityByTargetname( entity, m_killtarget ) ) !is null )
            {
                if( !entity.IsPlayer() && entity.entindex() != 0 )
                {
#if SERVER
                    g_Logger.trace( "Killing entity {}::{} at {}", { entity.pev.classname, m_killtarget, entity.pev.origin.ToString() } );
#endif
                    entity.UpdateOnRemove();
                    entity.pev.flags |= FL_KILLME;
                    entity.pev.targetname = 0;
                }
            }
        }

        if( target != String::EMPTY_STRING )
        {
            array<string> targets = { target };

            if( target.Find( ";", 0 ) != String::INVALID_INDEX )
            {
                targets = target.Split( ";" );
            }

            for( uint ui = 0; ui < targets.length(); ui ++ )
            {
                auto puse_type = m_usetype;

                if( targets[ui].Find( "#", 0 ) != String::INVALID_INDEX )
                {
                    array<string> target_usetype = targets[ui].Split( "#" );
                    targets[ui] = target_usetype[0];
                    puse_type = USE_TYPE( Math.clamp( USE_OFF, USE_KILL, atoi( target_usetype[1] ) ) );
                }

#if SERVER
                g_Logger.trace( "Entity {}::{}::{} firing targets \"{}\" with activator {} and use_type {}", {
                    self.entindex(), self.pev.classname, self.pev.targetname, target, (
                        activator.IsPlayer() ? activator.pev.netname : activator.pev.targetname ), puse_type } );
#endif

                g_EntityFuncs.FireTargets( target, activator, caller is null ? self : caller, puse_type, 0, m_delay );
            }
        }
    }

    void FireTarget( CBaseEntity@ activator, CBaseEntity@ caller = null )
    {
        FireTarget( string(pev.target), activator, caller );
    }
}
