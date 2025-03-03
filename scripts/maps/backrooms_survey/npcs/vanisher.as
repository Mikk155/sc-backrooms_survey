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

class CVanisherTargets : ScriptBaseEntity
{
    void Spawn()
    {
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );
    }

    void Use( CBaseEntity@ activator, CBaseEntity@ caller, USE_TYPE use_type, float value )
    {
        switch( use_type )
        {
            case USE_ON:
            {
                pev.spawnflags &= ~1;
                break;
            }
            case USE_OFF:
            {
                pev.spawnflags |= 1;
                break;
            }
            default:
            {
                self.Use( activator, caller, ( ( pev.spawnflags & 1 ) != 0 ? USE_ON : USE_OFF ), 0 );
                break;
            }
        }
    }
}

class CNPCVaisher : ScriptBaseEntity
{
    CBaseMonster@ m_hvanisher
    {
        get const
        {
            if( g_EntityFuncs.IsValidEntity( self.pev.owner ) )
            {
                return cast<CBaseMonster@>( g_EntityFuncs.Instance( self.pev.owner ) );
            }
            return null;
        }
    }

    void create_vanisher()
    {
        CBaseEntity@ entity = null;

        for( int i = 0; entity is null and i <= 3; i++ ) // i recall sometimes AS randomly fails so try again if needed.
            @entity = g_EntityFuncs.Create( "monster_zombie", pev.origin, pev.angles, true, self.edict() );

        g_EntityFuncs.DispatchKeyValue( entity.edict(), "freeroam", "2" );
        g_EntityFuncs.DispatchKeyValue( entity.edict(), "health", "1000" );
        g_EntityFuncs.DispatchKeyValue( entity.edict(), "bloodcolor", "1" );
        g_EntityFuncs.DispatchKeyValue( entity.edict(), "soundlist", "backrooms_survey/vanisher.gsr" );
        g_EntityFuncs.DispatchKeyValue( entity.edict(), "model", "models/backrooms_survey/npcs/vanisher.mdl" );
        g_EntityFuncs.DispatchKeyValue( entity.edict(), "displayname", "Vanisher" );
        g_EntityFuncs.DispatchKeyValue( entity.edict(), "targetname", "npc_vanisher" );

        g_EntityFuncs.DispatchSpawn( entity.edict() );

        g_EntityFuncs.SetOrigin( entity, self.pev.origin );

        @self.pev.owner = entity.edict();
    }

    void kill_vanisher()
    {
        auto vanisher = m_hvanisher;

        if( vanisher is null )
            return;

        vanisher.UpdateOnRemove();
        vanisher.pev.flags |= FL_KILLME;
        @self.pev.owner = null;
    }

    void Spawn()
    {
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        SetThink( ThinkFunction( this.think ) );
        pev.nextthink = g_Engine.time + 0.1f;
    }

    void think()
    {
        auto vanisher = m_hvanisher;

        if( vanisher is null )
            return;

        g_Game.AlertMessage( at_console, "Got vanisher monster.\n" );
    }

    void attack( CBasePlayer@ player )
    {
        array<CBaseEntity@> teleports = {};

        CBaseEntity@ teleport = null;

        while( ( @teleport = g_EntityFuncs.FindEntityByTargetname( teleport, "info_vanisher_destination" ) ) !is null && ( teleport.pev.spawnflags & 1 ) == 0 ) {
            teleports.insertLast( teleport );
        }

        auto size = teleports.length();

        if( size == 0 )
        {
            g_Game.AlertMessage( at_console, "No valid \"info_vanisher_destination\" entity.\n" );
            return;
        }

        auto vanisher_destination = teleports[ Math.RandomLong( 0, size - 1 ) ];

        player.SetOrigin( vanisher_destination.pev.origin );
        player.pev.fixangle = FAM_FORCEVIEWANGLES;
        player.pev.angles = player.pev.v_angle = vanisher_destination.pev.angles;

        g_EntityFuncs.FireTargets( vanisher_destination.pev.target, player, vanisher_destination, USE_TOGGLE, 0, 0 );
    }
}
