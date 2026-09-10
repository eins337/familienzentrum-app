// Disables/re-enables a user's login — bans them at the Auth level (not
// just a client-side flag) so a disabled account genuinely cannot sign in
// anywhere. Admin-only.
//
// Deploy: supabase functions deploy admin-set-user-disabled

import { corsHeaders } from '../_shared/cors.ts';
import { requireAdmin } from '../_shared/require_admin.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const admin = await requireAdmin(req);
    const { targetUserId, disabled } = await req.json();
    if (!targetUserId || typeof disabled !== 'boolean') {
      return json({ error: 'targetUserId und disabled sind erforderlich' }, 400);
    }

    const { error: banErr } = await admin.auth.admin.updateUserById(targetUserId, {
      ban_duration: disabled ? '876000h' : 'none',
    });
    if (banErr) return json({ error: banErr.message }, 500);

    const { error: profileErr } = await admin.from('profiles').update({ disabled }).eq('id', targetUserId);
    if (profileErr) return json({ error: profileErr.message }, 500);

    return json({ ok: true }, 200);
  } catch (e) {
    if (e instanceof Response) return e;
    return json({ error: e instanceof Error ? e.message : 'Unbekannter Fehler' }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
