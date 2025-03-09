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
    class CWeaponCamera : ScriptBasePlayerWeaponEntity
    {
        bool m_nightvision;
        float m_nightvision_battery = 10000.0f;
        int m_nightvision_radius;
        int m_nightvision_fog = 500;

        sprint_state m_sprint_state;
        float m_flNextSprintTime;

        // If watching a picture. this is greater than the engine's time
        float watching_picture;

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
                                g_EntityFuncs.DispatchKeyValue( camera.edict(), "wait", env_info.m_watch_time );
                                camera.Use( player, player, USE_ON, 0 );
                            }

                            if( env_info.pev.target != "" )
                            {
                                auto render = Rendering::Create( env_info.m_watch_time );

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

                            hud_message::param.channel = 3;
                            hud_message::param.holdTime = env_info.m_watch_time;
                            hud_message::print( player, env_info.buffer);

                            FireTargets( env_info.m_trigger_on_watch, player, entity, env_info.m_usetype, 0, env_info.m_delay, env_info.m_killtarget );

                            watching_picture = g_Engine.time + env_info.m_watch_time;
                            player.pev.button = 0;
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

            // Are we watching a picture?
            if( watching_picture > g_Engine.time )
            {
                // aren't space and enter the global language of "skip cinematic"?
                if( player.pev.button != 0 )
                {
                    auto camera = get_camera( player.entindex() );

                    if( camera !is null )
                    {
                        camera.Use( player, player, USE_OFF, 0 );
                    }

                    hud_message::param.channel = 3;
                    hud_message::param.holdTime = 0.0f;
                    hud_message::print( player, "\n" );

                    // .-TODO Check for flashlight active and remove/reset screenfade at peak level.

                    watching_picture = 0;
                }
                return;
            }

            if( ( player.pev.button & IN_USE ) != 0
            and watching_picture < g_Engine.time ) // Player is not watching a picture
            {
                auto user_data = player.GetUserData();

                auto pictures = cast<dictionary>( user_data[ "pictures" ] );

                auto pictures_t = pictures.getKeys();

                if( pictures_t.length() > 0 )
                {
                    menu::open( player, "Camera pictures", @pictures_t, TextMenuPlayerSlotCallback( this.picture_watch ) );
                }
                else
                {
                    hud_message::param.channel = 4;
                    hud_message::param.holdTime = 5.0f;
                    hud_message::print( player, "There are not any useful picture yet.\n" );
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

                hud_message::param.channel = 3;
                hud_message::param.holdTime = 0.2f;
                hud_message::print( player, m_nightvision_battery );

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

            // Find env_info entities
            auto user_data = player.GetUserData();

            auto pictured_entities = cast<dictionary>( user_data[ "pictures" ] );

            for( int ui = information_entities.length() - 1; ui >= 0; ui-- )
            {
                auto entity = g_EntityFuncs.Instance( information_entities[ui] );

                if( entity is null )
                {
                    information_entities.removeAt(ui);
                    continue;
                }

                auto env_info = cast<CEnvironmentInformation@>( CastToScriptClass( entity ) );

                if( env_info is null || ( env_info.pev.spawnflags & 1 ) != 0 )
                    continue;

                if( pictured_entities.exists( env_info.name ) )
                    continue;

                env_info.pictured( player );
            }

            CBaseEntity@ renders = null;

            while( ( @renders = g_EntityFuncs.FindEntityInSphere( renders, tr.vecEndPos, 1000, "env_camera_render", "classname" ) ) !is null )
            {
                auto render = cast<CCameraRender@>( CastToScriptClass( renders ) );

                if( render !is null && render.shouldtoggle() )
                {
                    render.picture();
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
