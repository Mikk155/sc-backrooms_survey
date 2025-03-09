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

#if SERVER
    CLogger@ FireTargets_Logger = CLogger( "Fire Targets" );
#endif

class FireTargets
{
    protected int _activator_;
    CBaseEntity@ activator
    {
        get const {
            return g_EntityFuncs.Instance( this._activator_ );
        }
        set {
            this._activator_ = value.entindex();
        }
    }

    protected int _caller_;
    CBaseEntity@ caller
    {
        get const {
            return g_EntityFuncs.Instance( this._caller_ );
        }
        set {
            this._caller_ = value.entindex();
        }
    }

    USE_TYPE use_type = USE_TOGGLE;
    float value;
    float delay;
    string target;
    string killtarget;

    FireTargets(
        const string &in _target,
        CBaseEntity@ _activator = null,
        CBaseEntity@ _caller = null,
        USE_TYPE _use_type = USE_TOGGLE,
        float _value = 0,
        float _delay = 0,
        const string &in _killtarget = String::EMPTY_STRING
    )
    {
        this.target = _target;
        @this.activator = _activator;
        @this.caller = _caller;
        this.use_type = _use_type;
        this.delay = _delay;
        this.value = _value;
        this.killtarget = _killtarget;
    }

    // Fire targets as soon as the class is not used anymore. Probably bad xd
    ~FireTargets()
    {
        if( this.delay > 0 )
        {
            g_Scheduler.SetTimeout( @this, "_FireTargets_", this.delay );

            #if SERVER
                FireTargets_Logger.trace( "Delayed of trigger {} in {}", { this.target, delay } );
            #endif
        }
        else
        {
            this._FireTargets_();
        }
    }

    // I miss Lambdas x[
    void KillTargets( const string &in s_killtarget )
    {
        if( s_killtarget != String::EMPTY_STRING )
        {
            CBaseEntity@ entity = null;

            while( ( @entity = g_EntityFuncs.FindEntityByTargetname( entity, s_killtarget ) ) !is null )
            {
                if( entity.entindex() <= g_Engine.maxClients + 2 ) // Worldspawn + soundent
                {
                    #if SERVER
                        FireTargets_Logger.trace( "Why are you trying to kill the poor {} entity? Lol", { entity.pev.classname } );
                    #endif

                    continue;
                }

                #if SERVER
                    FireTargets_Logger.trace( "Killing entity {}::{}::{} at {}", { entity.entindex(), entity.pev.classname, entity.pev.targetname, entity.pev.origin.ToString() } );
                #endif

                entity.UpdateOnRemove();
                entity.pev.flags |= FL_KILLME;
                entity.pev.targetname = 0;
            }
        }
    }

    protected void _FireTargets_()
    {
        KillTargets( this.killtarget );

        if( this.target != String::EMPTY_STRING )
        {
            array<string> targets = { this.target };

            // Split multiple targets by a semicolon
            if( this.target.Find( ";", 0 ) != String::INVALID_INDEX )
            {
                targets = this.target.Split( ";" );
            }

            for( uint ui = 0; ui < targets.length(); ui ++ )
            {
                auto new_usetype = this.use_type;

                // Add custom Trigger types like multi_manager does.
                if( targets[ui].Find( "#", 0 ) != String::INVALID_INDEX )
                {
                    array<string> target_usetype = targets[ui].Split( "#" );
                    targets[ui] = target_usetype[0];
                    new_usetype = USE_TYPE( Math.clamp( USE_OFF, USE_KILL, atoi( target_usetype[1] ) ) );
                }

                #if SERVER
                    FireTargets_Logger.trace( "Fire \"{}\"", { targets[ui] } );

                    if( this.activator !is null )
                    {
                        FireTargets_Logger.trace( "Activator: {}", { FireTargets_Logger.entname( activator ) } );
                    }

                    if( caller !is null )
                        FireTargets_Logger.trace( "Caller: {}", { FireTargets_Logger.entname( caller ) } );

                    FireTargets_Logger.trace( "USE_TYPE: {}", { FireTargets_Logger.usename(new_usetype) } );
                #endif

                // CEntityFuncs::FireTargets's "USE_KILL" doesn't even fucking work lol
                if( new_usetype == USE_KILL )
                {
                    KillTargets( targets[ui] );
                }
                else
                {
                    g_EntityFuncs.FireTargets( targets[ui], this.activator, this.caller, new_usetype, value );
                }
            }
        }
    }
}
