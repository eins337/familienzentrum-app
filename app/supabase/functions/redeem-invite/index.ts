// Redeems a one-time invite: creates the Auth account (email + the access
// code as password) and the matching profile row, then marks the invite
// spent. Runs with the service role key so it can bypass RLS — the
// `invites` table itself grants no read/write access to anon/authenticated
// clients at all, this function is the only door in.
//
// Deploy: supabase functions deploy redeem-invite --no-verify-jwt
// (no-verify-jwt because the caller isn't signed in yet.)

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { email, code } = await req.json();
    if (!email || !code) {
      return json({ error: 'email und code sind erforderlich' }, 400);
    }
    const normalizedEmail = String(email).trim().toLowerCase();

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: invite, error: inviteErr } = await supabase
      .from('invites')
      .select('*')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (inviteErr) return json({ error: inviteErr.message }, 500);
    if (!invite) {
      return json({ error: 'Diese E-Mail-Adresse ist nicht eingeladen. Frag dein Kita-Team nach einem Zugangscode.' }, 404);
    }
    if (invite.redeemed_at) {
      return json({ error: 'Dieser Zugangscode wurde bereits verwendet. Wenn du dich schon angemeldet hast, nutze dein bestehendes Passwort.' }, 409);
    }
    if (invite.code !== code) {
      return json({ error: 'Der Zugangscode stimmt nicht. Prüfe deinen Elternbrief.' }, 401);
    }

    const { data: created, error: createErr } = await supabase.auth.admin.createUser({
      email: normalizedEmail,
      password: code,
      email_confirm: true,
    });
    if (createErr || !created.user) {
      return json({ error: createErr?.message ?? 'Konto konnte nicht erstellt werden.' }, 500);
    }

    const { error: profileErr } = await supabase.from('profiles').insert({
      id: created.user.id,
      email: normalizedEmail,
      display_name: invite.display_name,
      role: invite.role,
      family_id: invite.family_id,
      is_admin: invite.is_admin ?? false,
      group_ids: invite.group_ids ?? [],
      staff_title: invite.staff_title,
      // Forces the new account straight into the password-change screen
      // (see force_password_change_screen.dart) so the invite code, used
      // here as the initial password, gets replaced right away.
      must_change_password: true,
    });
    if (profileErr) {
      // Roll back the just-created auth user so a failed redemption doesn't
      // leave an orphaned account with no profile.
      await supabase.auth.admin.deleteUser(created.user.id);
      return json({ error: profileErr.message }, 500);
    }

    if (invite.family_id) {
      await supabase.from('family_members').insert({
        family_id: invite.family_id,
        user_id: created.user.id,
        relation: invite.role === 'parent' ? 'Elternteil' : 'Team',
      });
    }

    await supabase.from('invites').update({ redeemed_at: new Date().toISOString() }).eq('email', normalizedEmail);

    return json({ ok: true }, 200);
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : 'Unbekannter Fehler' }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
