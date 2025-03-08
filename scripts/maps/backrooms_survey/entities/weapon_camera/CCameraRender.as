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

namespace camera
{
    class CCameraRender : ScriptBaseEntity, CToggleState, CFireTarget
    {
        string m_trigger_on_picture;
        float m_wait;

        bool KeyValue( const string& in key, const string& in value )
        {
            if( CFireTarget( key, value ) )
            {
                return true;
            }
            else if( key == "m_trigger_on_picture" )
            {
                m_trigger_on_picture = value;
                return true;
            }
            else if( key == "m_wait" )
            {
                m_wait = atof( value );
            }
            return false;
        }

        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );

            pev.nextthink = g_Engine.time + 0.1f;
            SetThink( ThinkFunction( this.map_activate ) );
        }

        void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
        {
            shouldtoggle( use_type );
        }

        void map_activate()
        {
            CBaseEntity@ target = null;

            while( ( @target = g_EntityFuncs.FindEntityByTargetname( target, string( pev.target ) ) ) !is null )
            {
                target.pev.effects |= EF_NODRAW;

                auto ckv = target.GetCustomKeyvalues();

                if( ( pev.spawnflags & 2 ) != 0 )
                {
                    g_EntityFuncs.DispatchKeyValue( target.edict(), "$i_old_solid_camera", target.pev.solid );
                    target.pev.solid = SOLID_NOT;
                }
            }
        }

        void picture()
        {
            CBaseEntity@ target = null;

            while( ( @target = g_EntityFuncs.FindEntityByTargetname( target, string( pev.target ) ) ) !is null )
            {
                target.pev.effects &= ~EF_NODRAW;

                auto ckv = target.GetCustomKeyvalues();

                if( ckv.HasKeyvalue( "$i_old_solid_camera" ) )
                {
                    target.pev.solid = SOLID( ckv.GetKeyvalue( "$i_old_solid_camera" ).GetInteger() );
                }
            }

            if( m_wait > 0 )
            {
                pev.nextthink = g_Engine.time + m_wait;
            }
        }
    }
}
