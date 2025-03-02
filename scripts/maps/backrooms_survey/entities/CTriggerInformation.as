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

class CTriggerInformation : ScriptBaseEntity
{
    string buffer;

    bool KeyValue( const string& in key, const string& in value )
    {
        if( key == "text_file" )
        {
            string szpath;
            snprintf( szpath, "scripts/maps/backrooms_survey/%1.txt", value );

            auto file = g_FileSystem.OpenFile( szpath, OpenFile::READ );

            if( file !is null && file.IsOpen() )
            {
                while( !file.EOFReached() )
                {
                    string line;
                    file.ReadLine( line );
                    snprintf( buffer, "%1\n%2", buffer, line );
                }
            }
        }
        return true;
    }

    void Spawn()
    {
        g_Game.AlertMessage( at_console, buffer + '\n' );
    }
}
