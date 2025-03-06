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
#if SERVER
        CLogger@ m_Logger = CLogger( "Reflection" );
#endif

        int Call( const string m_iszFunction, CHookModule@ pHookInfo )
        {
            int f = 0;

            for( uint i = 0; i < MAX_FUNCTIONS; i++ )
            {
                Reflection::Function@ m_fFunction = Reflection::g_Reflection.Module.GetGlobalFunctionByIndex( i );

                if( m_fFunction !is null && !m_fFunction.GetNamespace().IsEmpty() && m_fFunction.GetName() == m_iszFunction )
                {
                    f++;
#if SERVER
                    m_Logger.trace( "Called \"{}::{}\"", { m_fFunction.GetNamespace(), m_fFunction.GetName() } );
#endif
                    m_fFunction.Call( @pHookInfo );

                    if( pHookInfo.stop )
                    {
                        break;
                    }
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
            CHookModule@ pHookModule = CHookModule( "MapThink" );
            g_Reflection.Call( "On_MapThink", @pHookModule );
            pev.nextthink = g_Engine.time + 0.1f;
        }

        void Spawn()
        {
            self.pev.solid = SOLID_NOT;
            self.pev.movetype = MOVETYPE_NONE;
            SetThink( ThinkFunction( this.think ) );
            pev.nextthink = g_Engine.time + 0.1f;
            g_Reflection.m_Logger.info( "Registered function MapThink" );
        }
    }

    HookReturnCode PlayerSpawn( CBasePlayer@ player )
    {
        CHookModule@ pHookModule = CHookModule( "PlayerSpawn" );

        @pHookModule.player = player;

        g_Reflection.Call( "on_playerspawn", @pHookModule );

        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
    {
        CHookModule@ pHookModule = CHookModule( "PlayerTakeDamage" );

        @pHookModule.victim = pDamageInfo.pVictim;
        @pHookModule.player = cast<CBasePlayer@>( pHookModule.victim );
        @pHookModule.attacker = ( pDamageInfo.pAttacker !is null ? pDamageInfo.pAttacker : pDamageInfo.pInflictor );
        @pHookModule.inflictor = ( pDamageInfo.pInflictor !is null ? pDamageInfo.pInflictor : pDamageInfo.pAttacker );
        pHookModule.damage = pDamageInfo.flDamage;
        pHookModule.damage_bits = pDamageInfo.bitsDamageType;

        g_Reflection.Call( "on_playertakedamage", @pHookModule );

        @pDamageInfo.pVictim = pHookModule.victim;
        @pDamageInfo.pAttacker = pHookModule.attacker;
        @pDamageInfo.pInflictor = pHookModule.inflictor;
        @pDamageInfo.pInflictor = pHookModule.inflictor;
        pDamageInfo.flDamage = pHookModule.damage;
        pDamageInfo.bitsDamageType = pHookModule.damage_bits;

        return HOOK_CONTINUE;
    }
}

// idk how cool could this be. let's see while writting :aaagaben:
class CHookModule
{
    // The function's name that called this hook. don't think it's needed but here it is.
    string function;

    // Whatever to keep calling other hooks or stop.
    bool stop;

    CHookModule( const string& in _function )
    {
        function = _function;
    }

    CBasePlayer@ player;

    CBaseEntity@ victim;
    CBaseEntity@ attacker;
    CBaseEntity@ inflictor;
    float damage;
    int damage_bits;
}

ReflectionWorkspace::Reflection@ g_Reflection;

void MapInit()
{
    g_Reflection.Register();

    if( g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @ReflectionWorkspace::PlayerTakeDamage ) )
        g_Reflection.m_Logger.info( "Registered function PlayerTakeDamage" );
    if( g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @ReflectionWorkspace::PlayerSpawn ) )
        g_Reflection.m_Logger.info( "Registered function PlayerSpawn" );

    g_CustomEntityFuncs.RegisterCustomEntity( "ReflectionWorkspace::MapThink", "_map_think_" );
    g_EntityFuncs.Create( "_map_think_", g_vecZero, g_vecZero, false );

    CHookModule@ pHookModule;

    @pHookModule = CHookModule( "MapInit" );
    g_Reflection.Call( "On_MapPrecache", @pHookModule );

    @pHookModule = CHookModule( "MapInit" );
    g_Reflection.Call( "On_MapInit", @pHookModule );
}

void MapActivate()
{
    CHookModule@ pHookModule = CHookModule( "MapActivate" );
    g_Reflection.Call( "On_MapActivate", @pHookModule );
}

void MapStart()
{
    CHookModule@ pHookModule = CHookModule( "MapStart" );
    g_Reflection.Call( "On_MapStart", @pHookModule );
}

// This will *probably* be removed on release.
