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
    class CPicture
    {
        Vector position;
        Vector angles;
        EHandle handle;

        CPicture( Vector _position, Vector _angles, EHandle _handle )
        {
            position = _position;
            angles = _angles;
            handle = _handle;
        }
    }

#if SERVER
    CLogger@ m_Logger = CLogger( "Camera" );
#endif

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

    class CWeaponCamera : ScriptBasePlayerWeaponEntity
    {
        float m_flNextPictureTime;

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
            g_Game.PrecacheModel( "models/v_357.mdl" );
            g_Game.PrecacheModel( "models/p_medkit.mdl" );

            string sprite;
            snprintf( sprite, "sprites/backrooms/%1/.txt", pev.classname );
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

            player.pev.viewmodel = self.GetV_Model( "models/v_357.mdl" );
            player.pev.weaponmodel = self.GetP_Model( "models/p_medkit.mdl" );

            player.set_m_szAnimExtension( "python" );

    //        pev.body = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex( "models/v_357.mdl" ), pev.body, 0, 0 );
            self.SendWeaponAnim( PYTHON_DRAW, 0, pev.body );

            player.m_flNextAttack = 0;
            self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = g_Engine.time + 0.2;

            return true;
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
                    auto entity = picture.handle.GetEntity();

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

                if( !user_data.exists( "pictures" ) )
                    user_data[ "pictures" ] = dictionary();

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
                    g_PlayerFuncs.ClientPrint( player, HUD_PRINTTALK, "There are not any useful picture yet.\n" );
                    m_flNextPictureTime = g_Engine.time + 0.5f;
                    // -TODO HudTextMessage
                }
            }

            BaseClass.ItemPreFrame();
        }

        void ItemPostFrame()
        {
            BaseClass.ItemPostFrame();
        }

        void entities_on_sight()
        {
            auto player = m_hPlayer;

            if( player is null )
                return;

            auto user_data = player.GetUserData();

            if( !user_data.exists( "pictures" ) )
                user_data[ "pictures" ] = dictionary();

            auto pictured_entities = cast<dictionary>( user_data[ "pictures" ] );

            for( int ui = information_entities.length() - 1; ui >= 0; ui-- )
            {
                auto ehandle = information_entities[ui];

                if( !ehandle.IsValid() )
                {
                    information_entities.removeAt(ui);
                    continue;
                }

                auto entity = ehandle.GetEntity();

                if( entity is null || entity.pev.classname != "env_info" )
                    continue;

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
                    CPicture@ picture = CPicture( player.pev.origin + player.pev.view_ofs, player.pev.v_angle, ehandle );

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
        }

        void PrimaryAttack()
        {
            auto player = m_hPlayer;

            if( player is null )
                return;

            entities_on_sight();

            self.SendWeaponAnim( PYTHON_FIRE1, 0, 0 );

            player.SetAnimation( PLAYER_ATTACK1 );

            self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
        }

        void SecondaryAttack()
        {
            //-TODO Toggle night vision.
            self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
        }

        void Reload()
        {
            //-TODO Reload night vision battery
        }
    }
}
