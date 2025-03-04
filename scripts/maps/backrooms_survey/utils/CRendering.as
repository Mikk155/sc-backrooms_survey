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

enum RenderFlags
{
    renderfx = ( 1 << 0 ),
    renderamt = ( 1 << 1 ),
    rendermode = ( 1 << 2 ),
    rendercolor = ( 1 << 3 ),
};

class CRender
{
    // entindex of env_render_individual referenced.
    int index;

    // Expiration time
    float duration;

    CBaseEntity@ entity {
        get const {
            return g_EntityFuncs.Instance( this.index );
        }
        set {
            this.index = value.entindex();
        }
    }

    string_t target {
        get const {
            return entity.pev.target;
        }
        set {
            entity.pev.target = value;
        }
    }

    RenderFX renderfx {
        get const {
            return RenderFX( entity.pev.renderfx );
        }
        set {
            entity.pev.renderfx = value;
            entity.pev.spawnflags &= ~RenderFlags::rendermode;
        }
    }

    RenderModes rendermode {
        get const {
            return RenderModes( entity.pev.rendermode );
        }
        set {
            entity.pev.rendermode = value;
            entity.pev.spawnflags &= ~RenderFlags::rendermode;
        }
    }

    int renderamt {
        get const {
            return int( entity.pev.renderamt );
        }
        set {
            entity.pev.renderamt = value;
            entity.pev.spawnflags &= ~RenderFlags::renderamt;
        }
    }

    Vector rendercolor {
        get const {
            return entity.pev.rendercolor;
        }
        set {
            entity.pev.rendercolor = value;
        }
    }

    RGBA rgba {
        get const {
            return RGBA( int(entity.pev.rendercolor.y), int(entity.pev.rendercolor.x), int(entity.pev.rendercolor.z), int( entity.pev.renderamt ) );
        }
        set {
            entity.pev.rendercolor = Vector( value.r, value.g, value.b );
            entity.pev.spawnflags &= ~RenderFlags::rendercolor;
            if( value.a > 0 )
                this.renderamt = value.a;
        }
    }

    CRender( float _duration )
    {
        if( _duration > 0 )
            this.duration = g_Engine.time + _duration;

        auto render = g_EntityFuncs.Create( "env_render_individual", g_vecZero, g_vecZero, false );

        if( render !is null )
        {
            string name;
            snprintf( name, "%1_render", render.entindex() );
            render.pev.targetname = name;
            render.pev.spawnflags = 79;
            @entity = render;
        }
        else
        {
            g_Rendering.m_Logger.warn( "Failed on creating a env_render_individual for CRender instance." );
        }
    }

    ~CRender()
    {
        g_Rendering.m_Logger.trace( "CRender's Destructor called. removing env_render_individual at index {}", { this.index } );
        g_EntityFuncs.Remove( this.entity );
    }

    void add_player( CBasePlayer@ player ) {
        if( player !is null ) {
            entity.Use( player, null, USE_ON, 0 );
        }
    }

    void add_player_late( int index_player )
    {
        auto player = g_PlayerFuncs.FindPlayerByIndex( index_player );
        if( player !is null ) {
            this.add_player( player );
        }
    }

    void add_player( CBasePlayer@ player, float delay ) {
        if( player !is null ) {
            g_Scheduler.SetTimeout( @this, "add_player_late", delay, player.entindex() );
        }
    }

    void remove_player( CBasePlayer@ player ) {
        if( player !is null ) {
            entity.Use( player, null, USE_OFF, 0 );
        }
    }

    void remove_player_late( int index_player )
    {
        auto player = g_PlayerFuncs.FindPlayerByIndex( index_player );
        if( player !is null ) {
            this.remove_player( player );
        }
    }

    void remove_player( CBasePlayer@ player, float delay ) {
        if( player !is null ) {
            g_Scheduler.SetTimeout( @this, "remove_player_late", delay, player.entindex() );
        }
    }
}

class CRendering
{
    CLogger@ m_Logger = CLogger( "Rendering" );

    // Hold handles.
    array<CRender@> permanent;

    array<CRender@> temporal;

    CRender@ create( float duration = 0 )
    {
        auto render = CRender( duration );

        if( render is null )
        {
            m_Logger.warn( "Failed on creating a CRender instance." );
            return null;
        }

        m_Logger.trace( "Created env_render_individual for CRender class at index {}", { render.index } );

        if( duration > 0 ) {
            temporal.insertLast( @render );
        } else {
            m_Logger.warn( "CRender without a expiration time has been initialized at index {}.", { render.index } );
            permanent.insertLast( @render );
        }

        return @render;
    }

    void think()
    {
        auto size_a = this.temporal.length() - 1;

        for( int i = size_a; i >= 0; i-- )
        {
            CRender@ render = this.temporal[i];

            if( render is null )
            {
                m_Logger.warn( "CRender at index {} was null.", { render.index } );
                this.temporal.removeAt(i);
            }
            else if( render.duration < g_Engine.time )
            {
                @render = null;
                this.temporal.removeAt(i);
            }
        }
    }
}

CRendering g_Rendering;
