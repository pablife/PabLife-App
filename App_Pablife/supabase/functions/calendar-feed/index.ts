// Entrega o calendário assinado no iPhone, Google ou Outlook. Esses aplicativos
// não fazem login: quem autoriza é o link secreto, /calendar-feed/<link>.ics.
// O banco guarda só o hash do link (ver migração calendar_feeds).
import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "@supabase/supabase-js";
import { buildCalendar, plannerEvents, womenHealthEvents } from "./ics.js";

const PAST_DAYS = 90;
const TOKEN_PATTERN = /^[a-f0-9]{64}$/;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

const notFound = () => new Response("Calendário não encontrado", { status: 404 });

async function sha256(text: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function loadPlanner(userId: string, feed: Record<string, unknown>) {
  const since = new Date(Date.now() - PAST_DAYS * 86400000).toISOString();

  const { data: activities, error: activitiesError } = await supabase
    .from("tb_activities")
    .select(
      "id, type, name, description, due_at, all_day, " +
        "rule:tb_activity_recurrence_rules(start_at, by_week_day, timezone, deleted_at)",
    )
    .eq("user_id", userId)
    .in("type", ["task", "goal"])
    .is("deleted_at", null)
    .or(`due_at.gte."${since}",activity_recurrence_rule_id.not.is.null`)
    .limit(2000);
  if (activitiesError) throw activitiesError;

  const active = (activities ?? [])
    .map((row: Record<string, unknown>) => {
      const rule = row.rule as Record<string, unknown> | null;
      return { ...row, rule: rule && !rule.deleted_at ? rule : null };
    })
    // Tarefa repetida cuja regra foi apagada não tem mais dia para aparecer.
    .filter((row) => row.rule || row.due_at);

  const ids = active.map((row) => row.id as string);
  const { data: registers, error: registersError } = ids.length === 0
    ? { data: [], error: null }
    : await supabase
      .from("tb_activity_registers")
      .select("activity_id")
      .in("activity_id", ids)
      .is("deleted_at", null);
  if (registersError) throw registersError;

  const { data: appointments, error: appointmentsError } = await supabase
    .from("tb_appointments")
    .select(
      "id, start_of_scheduled_window, end_of_scheduled_window, " +
        "professional:tb_professionals!inner(user:tb_users!inner(full_name))",
    )
    .eq("scheduled_by", userId)
    .in("status", ["scheduled", "completed"])
    .is("deleted_at", null)
    .gte("start_of_scheduled_window", since)
    .limit(1000);
  if (appointmentsError) throw appointmentsError;

  return plannerEvents({
    activities: active,
    appointments: (appointments ?? []).map((row: Record<string, unknown>) => {
      const professional = row.professional as
        | { user?: { full_name?: string } }
        | null;
      return { ...row, professional_name: professional?.user?.full_name };
    }),
    doneActivityIds: new Set(
      (registers ?? []).map((row: { activity_id: string }) => row.activity_id),
    ),
    options: feed,
  });
}

async function loadWomenHealth(userId: string, discreet: boolean) {
  const { data: profile, error } = await supabase
    .from("tb_women_health_profiles")
    .select("trail, last_period, cycle_length, consent_at")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  return womenHealthEvents({ profile, discreet });
}

serve(async (req: Request) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return new Response("Método não permitido", { status: 405 });
  }

  const lastSegment = new URL(req.url).pathname.split("/").pop() ?? "";
  const token = lastSegment.replace(/\.ics$/, "");
  if (!TOKEN_PATTERN.test(token)) return notFound();

  try {
    const { data: feed, error } = await supabase
      .from("tb_calendar_feeds")
      .select(
        "id, user_id, kind, include_tasks, include_goals, " +
          "include_appointments, discreet_titles, " +
          "user:tb_users!inner(status, deleted_at)",
      )
      .eq("token_hash", await sha256(token))
      .maybeSingle();
    if (error) throw error;
    if (!feed) return notFound();

    const owner = feed.user as unknown as {
      status: string;
      deleted_at: string | null;
    };
    if (owner.status !== "active" || owner.deleted_at) return notFound();

    const isPlanner = feed.kind === "planner";
    const events = isPlanner
      ? await loadPlanner(feed.user_id, feed)
      : await loadWomenHealth(feed.user_id, feed.discreet_titles);

    const name = isPlanner
      ? "PabLife"
      : feed.discreet_titles
      ? "PabLife Bem-estar"
      : "PabLife Saúde da mulher";

    await supabase
      .from("tb_calendar_feeds")
      .update({ last_fetched_at: new Date().toISOString() })
      .eq("id", feed.id);

    return new Response(buildCalendar({ name, events }), {
      headers: {
        "Content-Type": "text/calendar; charset=utf-8",
        "Content-Disposition": 'inline; filename="pablife.ics"',
        "Cache-Control": "private, max-age=900",
      },
    });
  } catch (e) {
    console.error("calendar-feed:", (e as Error).message);
    // Erro 5xx: o aplicativo mantém o calendário atual e tenta de novo depois.
    return new Response("Tente novamente mais tarde", { status: 503 });
  }
});
