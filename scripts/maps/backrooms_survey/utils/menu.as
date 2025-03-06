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

namespace menu
{
    // Each player requires one own CTextMenu instance.
    array<CTextMenu@> menus(g_Engine.maxClients);

    void open( CBasePlayer@ player, const string &in title, array<string>@ options, TextMenuPlayerSlotCallback@ func, int time = 20 )
    {
        if( player is null || options.length() == 0 )
            return;

        @menus[ player.entindex() - 1 ] = null;

        auto menu = CTextMenu( func );

        if( menu is null )
            return;

        string str_print;
        snprintf( str_print, "\\w%1\\r\n", title );
        menu.SetTitle( str_print );

        for( uint ui = 0; ui < options.length(); ui++ )
        {
            string name = options[ui];

            snprintf( str_print, "\\y%1\\%2\n", name, ( ui == options.length() - 1 ? "w" : "r" ) );

            menu.AddItem( str_print, any( name ) );
        }

        menu.Register();
        menu.Open( time, 0, player );

        @menus[ player.entindex() - 1 ] = menu;
    }
}
