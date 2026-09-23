// Sends the invite email (with the access code) to a newly invited parent
// or team member, right after an admin creates the invite. Uses Resend
// (resend.com) — the API key is read from Supabase Vault (`RESEND_API_KEY`,
// stored via `select vault.create_secret(...)`) through the
// `public.get_vault_secret` RPC (migration 0022), rather than a
// Dashboard-configured Edge Function secret, so nothing extra needs
// setting up per environment. That RPC's EXECUTE is revoked from
// anon/authenticated and granted only to service_role — see the migration.
// Admin-only, like the other admin-* functions.
//
// Deploy: supabase functions deploy send-invite-email

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
    const { email, displayName, code } = await req.json();
    if (!email || !displayName || !code) {
      return json({ error: 'email, displayName und code sind erforderlich' }, 400);
    }

    const { data: resendKey, error: secretErr } = await admin.rpc('get_vault_secret', { secret_name: 'RESEND_API_KEY' });
    if (secretErr) return json({ error: `Secret konnte nicht gelesen werden: ${secretErr.message}` }, 500);
    if (!resendKey) {
      return json({ error: 'E-Mail-Versand ist noch nicht eingerichtet (RESEND_API_KEY fehlt im Vault).' }, 500);
    }

    const html = `
      <div style="font-family: -apple-system, sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #2d2a26;">Willkommen im Familienzentrum Lank</h2>
        <p>Hallo ${escapeHtml(displayName)},</p>
        <p>du wurdest für die App des Familienzentrums Lank eingeladen. Melde dich mit dieser E-Mail-Adresse und dem folgenden Zugangscode an:</p>
        <p style="font-size: 24px; font-weight: 700; letter-spacing: 3px; background: #f3ede4; padding: 14px 18px; border-radius: 10px; text-align: center;">${escapeHtml(code)}</p>
        <p>Nach der ersten Anmeldung wirst du gebeten, ein eigenes Passwort festzulegen — der Zugangscode oben funktioniert danach nicht mehr als Passwort.</p>
        <p style="color: #8a8378; font-size: 12px;">Diese E-Mail wurde automatisch vom Familienzentrum Lank verschickt.</p>
      </div>`;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: 'Familienzentrum Lank <onboarding@resend.dev>',
        to: [email],
        subject: 'Dein Zugang zur Familienzentrum Lank App',
        html,
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      return json({ error: `Resend-Fehler (${res.status}): ${body}` }, 500);
    }

    return json({ ok: true }, 200);
  } catch (e) {
    if (e instanceof Response) return e;
    return json({ error: e instanceof Error ? e.message : 'Unbekannter Fehler' }, 500);
  }
});

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
