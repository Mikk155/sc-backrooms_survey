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
*       - Gaftherman - Original ScriptBaseAnimating Entity -
*       - EdgarBarney - Model -
*/

namespace vanisher
{
    enum puddle_anims
    {
        idle = 0,
        expanding,
        expanded
    };

    class CVanisherEffects : ScriptBaseAnimating
    {
        void Spawn()
        {
            pev.movetype = MOVETYPE_TOSS;
            pev.solid = SOLID_NOT;

            g_EntityFuncs.SetModel( self, "models/brp/npcs/vanisher_puddle.mdl" );

            g_EntityFuncs.SetOrigin( self, pev.origin );

            pev.scale = Math.RandomFloat( 2.5, 3.5 );
            pev.sequence = puddle_anims::expanding;
            pev.framerate = 0.6f;
            pev.frame = 0;

            auto sprite = g_EntityFuncs.CreateSprite( "sprites/brp/vanisher.spr", pev.origin + g_Engine.v_up * 32, true );

            sprite.AnimateAndDie( 6.0f );
            sprite.pev.rendermode = kRenderTransAdd;
            sprite.pev.renderamt = 255;
            sprite.pev.scale = 1.3;

            g_EntityFuncs.DispatchKeyValue( sprite.edict(), "vp_type", 1 );

            pev.nextthink = g_Engine.time;
            SetThink( ThinkFunction( this.think ) );

            self.ResetSequenceInfo();
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            pev.renderamt = 255;
            pev.rendermode = kRenderTransTexture;
        }

        void think()
        {
            self.StudioFrameAdvance();
            pev.nextthink = g_Engine.time + 0.1;

            if( pev.rendermode == kRenderTransTexture )
            {
                pev.renderamt -= 1;

                if( pev.renderamt < 1 )
                    pev.flags |= FL_KILLME;
            }
        }
    }
}
