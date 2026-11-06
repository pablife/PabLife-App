import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const FROM_EMAIL = "PAB Life <pablifeapp@pablife.com.br>";
const REPLY_TO = "pabdesenvolvimento@gmail.com";
const DEFAULT_TZ = "America/Fortaleza";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

function patientTemplate(name: string, profName: string, profType: string, dateStr: string, timeStr: string) {
  return `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #0c1324; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #00C2A8 0%, #0C8DA1 50%, #C14086 100%); padding: 32px; text-align: center;">
        <h1 style="color: white; font-size: 24px; margin: 0;">✅ Consulta Confirmada!</h1>
      </div>
      <div style="padding: 32px; color: #dce1fb;">
        <p style="font-size: 16px; margin-bottom: 24px;">
          Olá, <strong>${name}</strong>!
        </p>
        <p style="font-size: 14px; color: #8c9295; margin-bottom: 24px;">
          Sua consulta foi agendada com sucesso. Confira os detalhes:
        </p>
        <div style="background-color: #191f31; border-radius: 12px; padding: 24px; margin-bottom: 24px;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 8px 0; color: #8c9295; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Profissional</td>
              <td style="padding: 8px 0; color: #dce1fb; font-size: 14px; text-align: right; font-weight: 600;">${profName}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #8c9295; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Especialidade</td>
              <td style="padding: 8px 0; color: #00C2A8; font-size: 14px; text-align: right; font-weight: 600;">${profType}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #8c9295; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Data</td>
              <td style="padding: 8px 0; color: #dce1fb; font-size: 14px; text-align: right; font-weight: 600;">${dateStr}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #8c9295; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Horário</td>
              <td style="padding: 8px 0; color: #dce1fb; font-size: 14px; text-align: right; font-weight: 600;">${timeStr}</td>
            </tr>
          </table>
        </div>
        <p style="font-size: 12px; color: #8c9295; text-align: center;">
          PAB Life — Sua plataforma de saúde e bem-estar 💚
        </p>
      </div>
    </div>`;
}

function professionalTemplate(profName: string, patientName: string, dateStr: string, timeStr: string) {
  return `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #0c1324; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #00C2A8 0%, #0C8DA1 50%, #C14086 100%); padding: 32px; text-align: center;">
        <h1 style="color: white; font-size: 24px; margin: 0;">📅 Nova Consulta Agendada</h1>
      </div>
      <div style="padding: 32px; color: #dce1fb;">
        <p style="font-size: 16px; margin-bottom: 24px;">
          Olá, <strong>${profName}</strong>!
        </p>
        <p style="font-size: 14px; color: #8c9295; margin-bottom: 24px;">
          Você tem uma nova consulta agendada. Confira os detalhes:
        </p>
        <div style="background-color: #191f31; border-radius: 12px; padding: 24px; margin-bottom: 24px;">
          <table style="width: 100%; border-collapse: collapse;">
            <tr>
              <td style="padding: 8px 0; color: #8c9295; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Paciente</td>
              <td style="padding: 8px 0; color: #dce1fb; font-size: 14px; text-align: right; font-weight: 600;">${patientName}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #8c9295; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Data</td>
              <td style="padding: 8px 0; color: #dce1fb; font-size: 14px; text-align: right; font-weight: 600;">${dateStr}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #8c9295; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Horário</td>
              <td style="padding: 8px 0; color: #00C2A8; font-size: 14px; text-align: right; font-weight: 600;">${timeStr}</td>
            </tr>
          </table>
        </div>
        <p style="font-size: 12px; color: #8c9295; text-align: center;">
          PAB Life — Sua plataforma de saúde e bem-estar 💚
        </p>
      </div>
    </div>`;
}

function sendEmail(to: string, subject: string, html: string) {
  return fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: FROM_EMAIL,
      reply_to: REPLY_TO,
      to: [to],
      subject,
      html,
    }),
  });
}

function formatDateTime(iso: string | null, tz: string) {
  if (!iso) return { dateStr: "Data não definida", timeStr: "Horário não definido" };
  const d = new Date(iso);
  let zone = tz;
  try {
    new Intl.DateTimeFormat("pt-BR", { timeZone: zone });
  } catch (_) {
    zone = DEFAULT_TZ;
  }
  return {
    dateStr: d.toLocaleDateString("pt-BR", {
      weekday: "long", day: "2-digit", month: "long", year: "numeric", timeZone: zone,
    }),
    timeStr: d.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit", timeZone: zone }),
  };
}

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // Só o gatilho do banco conhece este segredo (ver notify_appointment_email).
    const { data: allowed } = await supabase.rpc("appointment_email_secret_valid", {
      p_secret: req.headers.get("x-email-secret") ?? "",
    });
    if (allowed !== true) {
      return json({ error: "Não autorizado" }, 401);
    }

    const payload = await req.json();
    const { record } = payload;
    if (!record) {
      return json({ error: "No record provided" }, 400);
    }

    const { data: patient } = await supabase
      .from("tb_users")
      .select("full_name, email")
      .eq("id", record.scheduled_by)
      .single();

    const { data: professional } = await supabase
      .from("tb_professionals")
      .select("type, user_id, tb_users!tb_professionals_user_id_fkey(full_name, email)")
      .eq("id", record.professional_id)
      .single();

    if (!patient || !professional) {
      console.error("Paciente ou profissional não encontrado", {
        patient_id: record.scheduled_by,
        professional_id: record.professional_id,
      });
      return json({ error: "Paciente ou profissional não encontrado" }, 404);
    }

    // Fuso da consulta (padrão: Fortaleza)
    let tz = DEFAULT_TZ;
    if (record.appointment_time_id) {
      const { data: t } = await supabase
        .from("tb_appointment_times")
        .select("timezone")
        .eq("id", record.appointment_time_id)
        .maybeSingle();
      if (t?.timezone) tz = t.timezone;
    }

    const profName = professional.tb_users?.full_name || "Profissional";
    const profEmail = professional.tb_users?.email;
    const profType =
      professional.type === "nutritionist"
        ? "Nutricionista"
        : professional.type === "psychologist"
        ? "Psicólogo(a)"
        : "Profissional";

    const { dateStr, timeStr } = formatDateTime(record.start_of_scheduled_window ?? null, tz);

    const emails: Promise<Response>[] = [];
    if (patient.email) {
      emails.push(sendEmail(
        patient.email,
        `✅ Consulta confirmada — ${dateStr}`,
        patientTemplate(patient.full_name, profName, profType, dateStr, timeStr),
      ));
    }
    if (profEmail) {
      emails.push(sendEmail(
        profEmail,
        `📅 Nova consulta agendada — ${dateStr}`,
        professionalTemplate(profName, patient.full_name, dateStr, timeStr),
      ));
    }

    const results = await Promise.allSettled(emails);
    const responses = await Promise.all(
      results.map(async (r) => {
        if (r.status === "fulfilled") {
          return { status: r.value.status, body: await r.value.json().catch(() => ({})) };
        }
        return { error: String(r.reason) };
      }),
    );

    console.log("Email results:", JSON.stringify(responses));

    // Falha de envio não é mais escondida: devolve 502 e registra no log.
    // deno-lint-ignore no-explicit-any
    const failed = responses.some((r: any) => r.error || r.status < 200 || r.status >= 300);
    if (failed) {
      console.error("FALHA NO ENVIO DE E-MAIL DE CONSULTA", JSON.stringify(responses));
      return json({ success: false, results: responses }, 502);
    }
    return json({ success: true, results: responses });
  } catch (error) {
    console.error("Error:", error);
    return json({ error: (error as Error).message }, 500);
  }
});
