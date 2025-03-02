// Array of env_info entities
array<EHandle> information_entities = {};

// Array of CTextMenu for each player.
array<CTextMenu@> menus = {};

// Array of trigger_camera for each player
array<EHandle> trigger_cameras = {};

/*
    Get a per-player camera.

    If it doesn't exists we'll create one.
*/
CBaseEntity@ get_camera( int index )
{
    auto handle = trigger_cameras[ index - 1 ];

    if( handle.IsValid() )
    {
        auto camera = handle.GetEntity();

        if( camera !is null )
        {
            return @camera;
        }
    }

    dictionary keyvalue_data;

    // -TODO Required keyvalues on keyvalue_data for trigger_camera

    auto camera = g_EntityFuncs.CreateEntity( "trigger_camera", keyvalue_data, true );

    if( camera !is null )
    {
        trigger_cameras[ index - 1 ] = EHandle( camera );
        return @camera;
    }

    return null;
}

const float M_PI = ( 180.0 / 3.14159265358979323846 );
