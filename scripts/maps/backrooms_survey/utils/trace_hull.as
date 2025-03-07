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

// Trace a free hull around a specific vector
// `vec_destination`: the origin of a `matched hull_size` in within `radius`
// Returns whatever the operation did find a valid hull or not.
// This is really bad but here we go :aaagaben:
bool trace_hull( const Vector &in vec_center, HULL_NUMBER hull_size, int radius, Vector &out vec_destination )
{
    TraceResult tr;

    const float step_size = 16.0f;
    const int max_steps = int( radius / step_size );

    // Do a early trace before going on spiral
    g_Utility.TraceHull( vec_center, vec_center, dont_ignore_monsters, hull_size, null, tr );

    if( tr.fStartSolid == 0 && tr.fAllSolid == 0 )
    {
        vec_destination = tr.vecEndPos;
        return true;
    }

    for( int step = 1; step <= max_steps; ++step )
    {
        for( int x = -step; x <= step; ++x )
        {
            for( int y = -step; y <= step; ++y )
            {
                for( int z = -step; z <= step; ++z )
                {
                    if( x == 0 && y == 0 && z == 0 )
                        continue;

                    Vector test_point = vec_center + Vector( x * step_size, y * step_size, z * step_size );

                    g_Utility.TraceHull( test_point, test_point, dont_ignore_monsters, hull_size, null, tr );

                    if( tr.fStartSolid == 0 && tr.fAllSolid == 0 )
                    {
                        vec_destination = tr.vecEndPos;
                        return true;
                    }
                }
            }
        }
    }

    return false;
}
