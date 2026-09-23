// Changes a user's login email — this has to go through the Auth admin API
// (auth.users, not just the profiles table) so the account can still sign
// in with the new address afterwards. Admin-only.
//
// Inlines cors/requireAdmin instead of importing from ../_shared — the
// Supabase MCP deploy tool couldn't resolve the sibling-directory relative
// import when bundling (unlike the other functions here, which were
// deployed via the Supabase CLI, which handles it fine).
//
// Deploy: supabase functions deploy admin-update-user-email

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function requireAdmin(req: Request): Promise<SupabaseClient> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) throw unauthorized();

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const callerClient = createClient(supabaseUrl, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userErr } = await callerClient.auth.getUser();
  if (userErr || !userData.user) throw unauthorized();

  const admin = createClient(supabaseUrl, serviceRoleKey);
  const { data: profile } = await admin.from('profiles').select('is_admin').eq('id', userData.user.id).maybeSingle();
  if (!profile?.is_admin) throw forbidden();

  return admin;
}

function unauthorized() {
  return new Response(JSON.stringify({ error: 'Nicht angemeldet.' }), { status: 401 });
}
function forbidden() {
  return new Response(JSON.stringify({ error: 'Nur für Admins.' }), { status: 403 });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const admin = await requireAdmin(req);
    const { targetUserId, newEmail } = await req.json();
    if (!targetUserId || !newEmail) {
      return json({ error: 'targetUserId und newEmail sind erforderlich' }, 400);
    }
    const normalizedEmail = String(newEmail).trim().toLowerCase();

    const { error: authErr } = await admin.auth.admin.updateUserById(targetUserId, { email: normalizedEmail, email_confirm: true });
    if (authErr) return json({ error: authErr.message }, 500);

    const { error: profileErr } = await admin.from('profiles').update({ email: normalizedEmail }).eq('id', targetUserId);
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
