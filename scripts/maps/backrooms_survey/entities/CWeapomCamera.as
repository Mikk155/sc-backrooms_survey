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

enum camera_anim
{
    PYTHON_IDLE1 = 0,
    PYTHON_FIDGET,
    PYTHON_FIRE1,
    PYTHON_RELOAD,
    PYTHON_HOLSTER,
    PYTHON_DRAW,
    PYTHON_IDLE2,
    PYTHON_IDLE3
};

class CWeapomCamera : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_hPlayer
    {
        get const   { return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
        set     { self.m_hPlayer = EHandle( @value ); }
    }

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/w_medkit.mdl" );
        self.m_iDefaultAmmo = 5;
        self.FallInit();
    }

    void Precache()
    {
        self.PrecacheCustomModels();
        g_Game.PrecacheModel( "models/w_medkit.mdl" );
        g_Game.PrecacheModel( "models/v_medkit.mdl" );
        g_Game.PrecacheModel( "models/p_medkit.mdl" );

        string sprite;
        snprintf( sprite, "sprites/backrooms/%1/.txt", pev.classname )
    }

    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1 = 10;
        info.iAmmo1Drop = 1;
        info.iMaxAmmo2 = -1;
        info.iAmmo2Drop = -1;
        info.iMaxClip = WEAPON_NOCLIP;
        info.iSlot = 0;
        info.iPosition = 0;
        info.iId = g_ItemRegistry.GetIdForName( self.pev.classname );
        info.iFlags = ( ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY );
        info.iWeight    = WEIGHT;

        return true;
    }

    bool Deploy()
    {
        return self.DefaultDeploy( "models/v_medkit.mdl", "models/p_medkit.mdl", PYTHON_DRAW, "python", 0, 0 );
        self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
        return bResult;
    }

    void PrimaryAttack()
    {
        Vector vecSrc = m_pPlayer.GetGunPosition();

        //-TODO Find entities in the player's Field of view and get the information for them.

        self.SendWeaponAnim( PYTHON_FIRE1, 0, 0 );

        m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

        self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
    }

    void ItemPostFrame()
    {
        g_Game.AlertMessage( at_console, "Holding weapon\n" );
    }

    void SecondaryAttack()
    {
        //-TODO Toggle night vision.
        self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5;
    }

    void Reload()
    {
        if( self.m_iClip2 == 1 )
            return;

        //-TODO Reload night vision battery
    }
}
