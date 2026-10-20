import { createClient } from "@supabase/supabase-js";
export const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL ||
  "https://cbkddsztcivllpwzflkx.supabase.co";
export const publicKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  "sb_publishable_vVtVNjubYllxuSnfyzcolA_qk034IwO";
export const supabase = createClient(supabaseUrl, publicKey);
