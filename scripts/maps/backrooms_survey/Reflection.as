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
*       - Gaftherman - Author -
*       - Mikk155 - Author -
*/

#if SERVER
#include "utils/CLogger"
#endif

namespace ReflectionWorkspace
{
#if SERVER
    CLogger@ m_Logger = CLogger( "Reflection" );
#endif

    bool reflection_register = g_RegisterReflection();

    bool g_RegisterReflection()
    {
        Reflection reflect();
        @g_Reflection = @reflect;
        return true;
    }

    const uint MAX_FUNCTIONS = Reflection::g_Reflection.Module.GetGlobalFunctionCount();

    final class Reflection
    {
        int Call( const string m_iszFunction )
        {
            int f = 0;

            for( uint i = 0; i < MAX_FUNCTIONS; i++ )
            {
                Reflection::Function@ m_fFunction = Reflection::g_Reflection.Module.GetGlobalFunctionByIndex( i );

                if( m_fFunction !is null && !m_fFunction.GetNamespace().IsEmpty() && m_fFunction.GetName() == m_iszFunction )
                {
                    f++;
#if SERVER
                    m_Logger.info( "Called \"{}::{}\"", { m_fFunction.GetNamespace(), m_fFunction.GetName() } );
#endif
                    m_fFunction.Call();
                }
            }
            return f;
        }

        protected array<string> Functions(MAX_FUNCTIONS);

        void Register()
        {
            for( uint i = 0; i < MAX_FUNCTIONS; i++ )
            {
                Reflection::Function@ Func = Reflection::g_Reflection.Module.GetGlobalFunctionByIndex( i );

                if( Func !is null )
                {
                    Functions.insertAt( i, ( Func.GetNamespace().IsEmpty() ? '' : Func.GetNamespace() + '::' ) + Func.GetName() );
                }
            }
        }

        Reflection::Function@ opIndex( string m_iszFunction )
        {
            if( Functions.find( m_iszFunction ) < 0 )
            {
#if SERVER
                m_Logger.error( "GetFunction Couldn\'t find function \"{}:\"", { m_iszFunction } );
#endif
                return null;
            }

            return Reflection::g_Reflection.Module.GetGlobalFunctionByIndex( Functions.find( m_iszFunction ) );
        }
    }

    // Idk. schedules sucks.
    class MapThink : ScriptBaseEntity
    {
        void think()
        {
            g_Reflection.Call( "On_MapThink" );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;
            SetThink( ThinkFunction( this.think ) );
            pev.nextthink = g_Engine.time + 0.1f;
        }
    }
}

ReflectionWorkspace::Reflection@ g_Reflection;

void MapInit()
{
    g_Reflection.Register();

    g_CustomEntityFuncs.RegisterCustomEntity( "ReflectionWorkspace::MapThink", "_map_think_" );
    g_EntityFuncs.Create( "_map_think_", g_vecZero, g_vecZero, false );

    g_Reflection.Call( "On_MapPrecache" );

    g_Reflection.Call( "On_MapInit" );
}

void MapActivate()
{
    g_Reflection.Call( "On_MapActivate" );
}

void MapStart()
{
    g_Reflection.Call( "On_MapStart" );
}

// This will *probably* be removed on release.
