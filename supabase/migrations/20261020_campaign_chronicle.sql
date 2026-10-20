-- Applied through the connected Supabase project. Additive; no existing user tables touched.
CREATE TABLE public.iron_campaign_chronicles (
 id text PRIMARY KEY CHECK (id ~ '^[a-z0-9-]{1,64}$'),
 revision integer NOT NULL CHECK (revision BETWEEN 1 AND 100000),
 published boolean NOT NULL DEFAULT false,
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload)='object' AND octet_length(payload::text)<=131072),
 updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.iron_campaign_chronicles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.iron_campaign_chronicles FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.iron_campaign_chronicles TO anon,authenticated;
CREATE POLICY iron_read_published_chronicles ON public.iron_campaign_chronicles
 FOR SELECT TO anon,authenticated USING (published=true);
-- Story is curated, versioned prose. The client receives no remote code, balance effects,
-- save data or administrative credentials. Offline v1 is shipped in godot/campaign/.
