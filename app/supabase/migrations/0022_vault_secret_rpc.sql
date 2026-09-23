-- Exposes a Vault secret to the service-role client only, via RPC rather
-- than querying vault.decrypted_secrets directly through PostgREST (the
-- vault schema isn't exposed there, and this keeps the read narrowly
-- scoped and auditable). Used by the send-invite-email Edge Function to
-- fetch RESEND_API_KEY without needing a Dashboard-configured secret.
create or replace function public.get_vault_secret(secret_name text)
returns text language plpgsql security definer set search_path = public, vault as $$
declare
  v_secret text;
begin
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = secret_name;
  return v_secret;
end;
$$;

revoke execute on function public.get_vault_secret(text) from public;
revoke execute on function public.get_vault_secret(text) from anon;
revoke execute on function public.get_vault_secret(text) from authenticated;
grant execute on function public.get_vault_secret(text) to service_role;
