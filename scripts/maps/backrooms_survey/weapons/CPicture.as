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
