import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';

/// Verifies the caller's JWT belongs to an admin profile. Returns the
/// service-role client (for the caller to act with elevated privileges)
/// or throws a Response to be returned directly by the function.
export async function requireAdmin(req: Request): Promise<SupabaseClient> {
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
