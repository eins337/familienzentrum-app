// Permanently deletes a user's Auth account. The `profiles` row cascades
// away automatically (FK: profiles.id references auth.users(id) on delete
// cascade). Admin-only.
//
// Deploy: supabase functions deploy admin-delete-user

import { corsHeaders } from '../_shared/cors.ts';
import { requireAdmin } from '../_shared/require_admin.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const admin = await requireAdmin(req);
    const { targetUserId } = await req.json();
    if (!targetUserId) return json({ error: 'targetUserId ist erforderlich' }, 400);

    const { error } = await admin.auth.admin.deleteUser(targetUserId);
    if (error) return json({ error: error.message }, 500);

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
