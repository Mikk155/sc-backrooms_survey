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
*       - KernCore91 - Some functionality -
*           - https://github.com/KernCore91/-SC-Cry-of-Fear-Weapons-Project/blob/master/scripts/maps/cof/special/weapon_cofcamera.as
*/

namespace camera
{
    // Array of env_info entities
    array<int> information_entities = {};

    class CPicture
    {
        Vector position;
        Vector angles;
        int index;

        CPicture( Vector _position, Vector _angles, int _index )
        {
            position = _position;
            angles = _angles;
            index = _index;
        }
    }

#if SERVER
    CLogger@ m_Logger = CLogger( "Camera" );
#endif

    enum camera_anim
    {
        CoFCAMERA_IDLE = 0,
        CoFCAMERA_DRAW_FIRST,
        CoFCAMERA_HOLSTER,
        CoFCAMERA_SHOOT,
        CoFCAMERA_FIDGET1,
        CoFCAMERA_JUMP_TO,
        CoFCAMERA_JUMP_FROM,
        CoFCAMERA_DRAW,
        CoFCAMERA_FIDGET2,
        CoFCAMERA_FIDGET3,
        CoFCAMERA_SPRINT_TO,
        CoFCAMERA_SPRINT_IDLE,
        CoFCAMERA_SPRINT_FROM,
        CoFCAMERA_MELEE 
    };

    enum sprint_state
    {
        sprint_no = 0,
        sprint_start,
        sprint_loop,
        sprint_end
    };

    class CWeaponCamera : ScriptBasePlayerWeaponEntity
    {
        float m_flNextPictureTime;

        bool m_nightvision;
        float m_nightvision_battery = 10000.0f;
        int m_nightvision_radius;
        int m_nightvision_fog = 500;

        sprint_state m_sprint_state;
        float m_flNextSprintTime;

        private CBasePlayer@ m_hPlayer
        {
            get const   { return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
            set     { self.m_hPlayer = EHandle( @value ); }
        }

        void Spawn()
        {
            g_EntityFuncs.SetModel( self, "models/cof/camera/wld.mdl" );
            self.m_iDefaultAmmo = 5;
            self.FallInit();
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 = 5;
            info.iAmmo1Drop = 1;
            info.iMaxAmmo2 = WEAPON_NOCLIP;
            info.iAmmo2Drop = WEAPON_NOCLIP;
            info.iMaxClip = 1;
            info.iSlot = 0;
            info.iPosition = 6;
            info.iId = g_ItemRegistry.GetIdForName( self.pev.classname );
            info.iFlags = ( ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_SELECTONEMPTY );
            info.iWeight = 10;

            return true;
        }

        bool Deploy()
        {
            auto player = m_hPlayer;

            if( player is null )
                return false;

            auto user_data = player.GetUserData();

            if( !user_data.exists( "pictures" ) )
                user_data[ "pictures" ] = dictionary();

            player.pev.viewmodel = self.GetV_Model( "models/cof/camera/vwm.mdl" );
            player.pev.weaponmodel = self.GetP_Model( "models/cof/camera/wld.mdl" );

            player.set_m_szAnimExtension( "trip" );

    //        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( "models/cof/camera/vwm.mdl" ), pev.body, 0, 0 );
            self.SendWeaponAnim( CoFCAMERA_DRAW, 0, pev.body );

            player.m_flNextAttack = 0;
            self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + 0.2;

            return true;
        }

        void Holster( int skiplocal = 0 )
        {
            shutdown_nightvision(m_nightvision);
            m_sprint_state = sprint_state::sprint_no;
        }

        void WeaponIdle()
        {
            auto player = m_hPlayer;

            if( self.m_flTimeWeaponIdle > g_Engine.time || player is null )
                return;

            switch( Math.RandomLong( 0, 3 ) )
            {
                case 1:
                    self.SendWeaponAnim( CoFCAMERA_FIDGET1, 0, 0 );
                break;

                case 2:
                    self.SendWeaponAnim( CoFCAMERA_FIDGET2, 0, 0 );
                break;

                case 3:
                    self.SendWeaponAnim( CoFCAMERA_FIDGET3, 0, 0 );
                break;

                default:
                    self.SendWeaponAnim( CoFCAMERA_IDLE, 0, 0 );
                break;
            }

            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( player.random_seed, 2, 4 );
        }

        void picture_watch( CTextMenu@ menu, CBasePlayer@ player, int iSlot, const CTextMenuItem@ item )
        {
            if( player !is null && item !is null )
            {
                string item_name;
                item.m_pUserData.retrieve( item_name );

                auto pictures = cast<dictionary>( player.GetUserData()[ "pictures" ] );

                CPicture@ picture = cast<CPicture@>( pictures[ item_name ] );

                if( picture !is null )
                {
                    auto entity = g_EntityFuncs.Instance( picture.index );

                    if( entity !is null )
                    {
                        auto env_info = cast<CEnvironmentInformation@>( CastToScriptClass( entity ) );

                        if( env_info !is null )
                        {
                            auto camera = get_camera( player.entindex() );

                            if( camera !is null )
                            {
                                camera.SetOrigin( picture.position );
                                camera.pev.angles = picture.angles;
                                camera.Use( player, player, USE_ON, 0 );
                            }

                            if( env_info.pev.target != "" )
                            {
                                // -TODO Custom camera time? need to update rendering. holdTime and camera's wait
                                auto render = g_Rendering.create( 10.0 );

                                if( env_info.target_has_rendermode )
                                    render.rendermode = env_info.target_rendermode;
                                if( env_info.target_has_renderamt )
                                    render.renderamt = env_info.target_renderamt;
                                if( env_info.target_has_renderfx )
                                    render.renderfx = env_info.target_renderfx;
                                if( env_info.target_has_rendercolor )
                                    render.rendercolor = env_info.target_rendercolor;

                                render.target = env_info.pev.target;

                                render.add_player( player );
                            }

                            hud_msg.holdTime = 10.0f;
                            g_PlayerFuncs.HudMessage( player, hud_msg, env_info.buffer );
                        }
                    }
                }
            }

            if( menu !is null || menu.IsRegistered() )
            {
                menu.Unregister();
                @menu = null;
            }
        }

        void ItemPreFrame()
        {
            auto player = m_hPlayer;

            if( player is null )
                return;

            if( ( player.pev.button & IN_USE ) != 0
            and m_flNextPictureTime < g_Engine.time
            and ( player.pev.flags & FL_GODMODE ) == 0 ) // Player is not watching a picture
            {
                auto user_data = player.GetUserData();

                auto pictures = cast<dictionary>( user_data[ "pictures" ] );

                auto pictures_t = pictures.getKeys();

                if( pictures_t.length() > 0 )
                {
                    @menus[ player.entindex() - 1 ] = null;

                    auto menu = CTextMenu( TextMenuPlayerSlotCallback( this.picture_watch ) );

                    if( menu !is null )
                    {
                        string str_print;

                        snprintf( str_print, "\\w%1\\r\n", "Camera pictures" );
                        menu.SetTitle( str_print );

                        for( uint ui = 0; ui < pictures_t.length(); ui++ )
                        {
                            string name = pictures_t[ui];

                            snprintf( str_print, "\\y%1\\%2\n", name, ( ui == pictures_t.length() - 1 ? "g" : "r" ) );

                            menu.AddItem( str_print, any( name ) );
                        } // when fucking "goto" x[

                        menu.Register();
                        menu.Open( 20.0f, 0, player );

                        @menus[ player.entindex() - 1 ] = menu;

                        m_flNextPictureTime = g_Engine.time + 0.5f;
                    }
                }
                else
                {
                    hud_msg.holdTime = 5.0f;
                    g_PlayerFuncs.HudMessage( player, hud_msg, "There are not any useful picture yet.\n" );
                    m_flNextPictureTime = g_Engine.time + 0.5f;
                }
            }

            bool on_ground = ( ( player.pev.flags & FL_ONGROUND ) != 0 );

            if( g_Engine.time > m_flNextSprintTime && on_ground )
            {
                if( m_sprint_state == sprint_state::sprint_no )
                {
                    if( player.pev.velocity.Make2D().Length() > 100 )
                    {
                        self.SendWeaponAnim( CoFCAMERA_SPRINT_TO, 0, 0 );
                        m_sprint_state = sprint_state::sprint_start;
                        m_flNextSprintTime = g_Engine.time + 0.3f;
                        self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
                    }
                }
                else if( m_sprint_state == sprint_state::sprint_start )
                {
                    self.SendWeaponAnim( CoFCAMERA_SPRINT_IDLE, 0, 0 );
                    m_sprint_state = sprint_state::sprint_loop;
                    m_flNextSprintTime = g_Engine.time + 0.5f;
                    self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
                }
                else if( player.pev.velocity.Make2D().Length() > 100 )
                {
                    self.SendWeaponAnim( CoFCAMERA_SPRINT_IDLE, 0, 0 );
                    m_flNextSprintTime = g_Engine.time + 0.65f;
                    self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
                }
            }
            else if( m_sprint_state == sprint_state::sprint_loop && ( player.pev.velocity.Make2D().Length() <= 100 || !on_ground ) )
            {
                self.SendWeaponAnim( CoFCAMERA_SPRINT_FROM, 0, 0 );
                m_sprint_state = sprint_state::sprint_no;
                m_flNextSprintTime = g_Engine.time + 0.5f;
                self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
            }

            if( m_nightvision )
            {
                if( m_nightvision_radius <= 100 ) {
                    m_nightvision_radius++;
                }

                NetworkMessage m( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, player.edict() );
                    m.WriteByte( TE_DLIGHT );
                    m.WriteCoord(player.pev.origin.x);
                    m.WriteCoord(player.pev.origin.y);
                    m.WriteCoord(player.pev.origin.z);
                    m.WriteByte(m_nightvision_radius);
                    m.WriteByte(255);
                    m.WriteByte(255);
                    m.WriteByte(255);
                    m.WriteByte(2);
                    m.WriteByte(1);
                m.End();

                if( m_nightvision_fog > 10 ) {
                    m_nightvision_fog = Math.clamp( 10, 500, m_nightvision_fog - 9 );

                    NetworkMessage fog( MSG_ONE_UNRELIABLE, NetworkMessages::Fog, player.edict() );
                        fog.WriteShort(0);
                        fog.WriteByte(1);
                        fog.WriteCoord(0);
                        fog.WriteCoord(0);
                        fog.WriteCoord(0);
                        fog.WriteShort(0);
                        fog.WriteByte(0); // R
                        fog.WriteByte(10); // G
                        fog.WriteByte(0); // B
                        fog.WriteShort(m_nightvision_fog); // StartDist
                        fog.WriteShort(500); // EndDist
                    fog.End();
                }

                m_nightvision_battery--;

                hud_msg.holdTime = 0.5f;
                g_PlayerFuncs.HudMessage( player, hud_msg, m_nightvision_battery );

                if( m_nightvision_battery <= 0 )
                {
                    self.SecondaryAttack();
                    self.m_iClip--;
                }
            }

            BaseClass.ItemPreFrame();
        }

        void PrimaryAttack()
        {
            auto player = m_hPlayer;

            if( player is null )
                return;

            self.SendWeaponAnim( CoFCAMERA_SHOOT );

            TraceResult tr;
            g_Utility.TraceLine( player.GetGunPosition(), player.GetGunPosition() + g_Engine.v_forward * 128, dont_ignore_monsters, dont_ignore_glass, player.edict(), tr );

            NetworkMessage msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
                msg.WriteByte( TE_DLIGHT );
                msg.WriteCoord( tr.vecEndPos.x );
                msg.WriteCoord( tr.vecEndPos.y );
                msg.WriteCoord( tr.vecEndPos.z );
                msg.WriteByte( 128 );
                msg.WriteByte( 254 );
                msg.WriteByte( 254 );
                msg.WriteByte( 254 );
                msg.WriteByte( 1 );
                msg.WriteByte( 100 );
            msg.End();

            player.SetAnimation( PLAYER_ATTACK1 );

            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "cof/guns/camera/photo.ogg", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_STATIC, "cof/guns/camera/charge.ogg", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

            auto user_data = player.GetUserData();

            auto pictured_entities = cast<dictionary>( user_data[ "pictures" ] );

            for( int ui = information_entities.length() - 1; ui >= 0; ui-- )
            {
                auto entity = g_EntityFuncs.Instance( information_entities[ui] );

                if( entity is null || entity.pev.classname != "env_info" )
                {
                    information_entities.removeAt(ui);
                    continue;
                }

                auto env_info = cast<CEnvironmentInformation@>( CastToScriptClass( entity ) );

                if( env_info is null || ( env_info.pev.spawnflags & 1 ) != 0 )
                    continue;

                if( pictured_entities.exists( env_info.name ) )
                    continue;

                auto vec_ent_to_player = ( env_info.pev.origin - player.pev.origin ).Normalize();

                g_EngineFuncs.MakeVectors( player.pev.v_angle );

                float dot_prod = DotProduct( g_Engine.v_forward, vec_ent_to_player );
                float dot_right = DotProduct( g_Engine.v_right,     vec_ent_to_player );
                float dot_updw = DotProduct( g_Engine.v_up,        vec_ent_to_player );

                float angle_yaw = abs( atan2( dot_right, dot_prod ) * M_PI );
                float angle_upd = abs( atan2( dot_updw, dot_prod ) * M_PI );

                auto total_distance = ( entity.Center() - player.pev.origin ).Length();

                if( total_distance < 1000 && angle_yaw <= 60.0 && angle_upd <= 50.0 )
                {
                    CPicture@ picture = CPicture( player.pev.origin + player.pev.view_ofs, player.pev.v_angle, entity.entindex() );

                    if( picture !is null )
                    {
                        pictured_entities[ env_info.name ] = @picture;
                        user_data[ "pictures" ] = pictured_entities;

                        if( ( entity.pev.spawnflags & 2 ) == 0 ) // Don't draw glow sprite.
                        {
                            auto spr = g_EntityFuncs.CreateSprite( ( env_info.glow_sprite != "" ? env_info.glow_sprite : "sprites/glow01.spr" ), entity.pev.origin, true );

                            if( spr !is null )
                            {
                                spr.AnimateAndDie( env_info.sprite_framerate);
                                spr.pev.rendermode = env_info.sprite_rendermode;
                                spr.pev.renderamt = env_info.sprite_renderamt;
                                spr.pev.rendercolor = env_info.sprite_rendercolor;
                            }
                        }
                    }
                }
            }

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.3f;
        }

        void SecondaryAttack()
        {
            auto player = m_hPlayer;

            if( self.m_iClip == 0 || player is null )
                return;

            m_nightvision = !m_nightvision;

            if( m_nightvision )
            {
                NetworkMessage mlight( MSG_ONE_UNRELIABLE, NetworkMessages::NetworkMessageType(12), player.edict() );
                mlight.WriteByte( 0 );
                mlight.WriteString( "z" );
                mlight.End();

                self.SendWeaponAnim( CoFCAMERA_HOLSTER );
                g_PlayerFuncs.ScreenFade( player, Vector( 0, 200, 20 ), 1.0f, 0.5f, 100.0f, FFADE_STAYOUT | FFADE_MODULATE | FFADE_OUT );
                g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "cof/guns/camera/charge.ogg", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
            }
            else
            {
                shutdown_nightvision(true);
                self.SendWeaponAnim( CoFCAMERA_DRAW_FIRST );
                self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.63f;
            }
        }

        void shutdown_nightvision( bool was_on )
        {
            auto player = m_hPlayer;

            if( player !is null )
            {
                if( was_on )
                {
                    NetworkMessage fog( MSG_ONE_UNRELIABLE, NetworkMessages::Fog, player.edict() );
                        fog.WriteShort(0);
                        fog.WriteByte(0);
                        fog.WriteCoord(0);
                        fog.WriteCoord(0);
                        fog.WriteCoord(0);
                        fog.WriteShort(0);
                        fog.WriteByte(0); // R
                        fog.WriteByte(10); // G
                        fog.WriteByte(0); // B
                        fog.WriteShort(10); // StartDist
                        fog.WriteShort(500); // EndDist
                    fog.End();

                    NetworkMessage mlight( MSG_ONE_UNRELIABLE, NetworkMessages::NetworkMessageType(12), player.edict() );
                    mlight.WriteByte( 0 );
                    mlight.WriteString( "m" );
                    mlight.End();

                    g_PlayerFuncs.ScreenFade( player, Vector( 0, 200, 20 ), 1.0f, 0.5f, 100.0f, FFADE_MODULATE );
                    g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "cof/guns/camera/lever.ogg", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                }
            }

            m_nightvision = false;
            m_nightvision_radius = 0;
            m_nightvision_fog = 500;
        }

        void Reload()
        {
            auto player = m_hPlayer;

            if( self.m_iClip != 0 || player is null )
                return;

            auto ammo = player.m_rgAmmo( self.m_iPrimaryAmmoType );

            if( ammo <= 0 )
            {
                g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
                return;
            }

            ammo--;
            self.m_iClip = 1;
            m_nightvision_battery = 10000.0f;
            player.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

            self.SendWeaponAnim( CoFCAMERA_SHOOT );

            g_SoundSystem.EmitSoundDyn( player.edict(), CHAN_WEAPON, "cof/guns/camera/lever.ogg", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

            self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.3f;
        }
    }
}
