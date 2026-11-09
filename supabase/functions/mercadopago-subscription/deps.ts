import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.23.8/mod.ts";

export { createClient, z };
export type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
