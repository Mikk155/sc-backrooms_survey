# Since you can't define preproccessors in Sven Co-op's AngelScript.
# This script will toggle the "SERVER" with "DEBUG" for testing purposes.

import os

def toggle_angelscript_preproccessors() -> None:

    from_to: list[str] = False;

    src_path  = os.path.join( os.path.join( os.path.join( os.path.dirname( __file__ ), "scripts" ), "maps" ), "backrooms_survey" );

    for root, dirs, files in os.walk( src_path ):

        for file in files:

            src_file = os.path.join( root, file );

            if src_file.endswith( ".as" ):

                angelscript = open( src_file, "r" ).read();

                if not from_to:

                    if angelscript.find( "#if SERVER" ) != -1:

                        from_to = [ "SERVER", "DEVELOP" ];

                    elif angelscript.find( "#if DEVELOP" ) != -1:

                        from_to = [ "DEVELOP", "SERVER" ];

                if from_to:

                    angelscript = angelscript.replace( f"#if {from_to[0]}", f"#if {from_to[1]}" );

                    open( src_file, 'w' ).write( angelscript );

    for file in files:

        if os.path.exists( file ) and file.endswith( ".as" ):

            lines = open( file, 'r' ).read();


    return None;

toggle_angelscript_preproccessors();
