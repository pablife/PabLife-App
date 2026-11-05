// Monta o arquivo de calendário (.ics). Não fala com o banco nem com a rede,
// e é JavaScript puro para os testes rodarem no Node (ics_test.mjs).

const DEFAULT_TZ = "America/Sao_Paulo";
const WEEK_DAYS = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
const TIMED_TASK_MINUTES = 30;
const DEFAULT_APPOINTMENT_MINUTES = 60;
const FUTURE_CYCLE_DAYS = 365;
const MAX_MENOPAUSE_MONTHS = 120;

export const FERTILE_NOTICE =
  "Estimativa baseada nas datas informadas. Não serve como método " +
  "contraceptivo nem substitui a orientação médica.";

// ------------------------------------------------------------------ datas

function pad(value, size = 2) {
  return String(value).padStart(size, "0");
}

/** Dia e hora de um instante no fuso pedido. */
function localParts(iso, timeZone) {
  const parts = {};
  const format = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
  for (const { type, value } of format.formatToParts(new Date(iso))) {
    parts[type] = value;
  }
  return parts;
}

function localDate(iso, timeZone) {
  const p = localParts(iso, timeZone);
  return `${p.year}-${p.month}-${p.day}`;
}

function addDays(date, days) {
  const [year, month, day] = date.split("-").map(Number);
  const moved = new Date(Date.UTC(year, month - 1, day + days));
  return moved.toISOString().slice(0, 10);
}

function addMonths(date, months) {
  const [year, month, day] = date.split("-").map(Number);
  const lastDay = new Date(Date.UTC(year, month - 1 + months + 1, 0))
    .getUTCDate();
  const moved = new Date(
    Date.UTC(year, month - 1 + months, Math.min(day, lastDay)),
  );
  return moved.toISOString().slice(0, 10);
}

function daysBetween(from, to) {
  return Math.round((Date.parse(to) - Date.parse(from)) / 86400000);
}

function weekDayOf(date) {
  return new Date(Date.parse(date)).getUTCDay();
}

function utcStamp(iso) {
  return new Date(iso).toISOString().replace(/[-:]/g, "").replace(
    /\.\d{3}Z$/,
    "Z",
  );
}

function compactDate(date) {
  return date.replaceAll("-", "");
}

/** Só guardamos fusos reais; regras antigas podem ter "UTC". */
function ruleTimeZone(value) {
  if (!value || value === "UTC") return DEFAULT_TZ;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: value });
    return value;
  } catch {
    return DEFAULT_TZ;
  }
}

// --------------------------------------------------------------- arquivo

function escapeText(text) {
  return String(text)
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r?\n/g, "\\n");
}

/** Linhas do formato têm no máximo 75 bytes; o resto continua com um espaço. */
function foldLine(line) {
  const encoder = new TextEncoder();
  const lines = [];
  let current = "";
  let size = 0;
  for (const char of line) {
    const charSize = encoder.encode(char).length;
    if (size + charSize > 75) {
      lines.push(current);
      current = " ";
      size = 1;
    }
    current += char;
    size += charSize;
  }
  lines.push(current);
  return lines.join("\r\n");
}

function eventLines(event, stamp) {
  const lines = [
    "BEGIN:VEVENT",
    `UID:${event.uid}@pablife.com.br`,
    `DTSTAMP:${stamp}`,
  ];
  if (event.allDay) {
    lines.push(
      `DTSTART;VALUE=DATE:${compactDate(event.start)}`,
      `DTEND;VALUE=DATE:${compactDate(event.end)}`,
      "TRANSP:TRANSPARENT",
    );
  } else if (event.localStart) {
    lines.push(
      `DTSTART;TZID=${event.timeZone}:${event.localStart}`,
      `DURATION:PT${event.minutes}M`,
    );
  } else {
    lines.push(
      `DTSTART:${utcStamp(event.start)}`,
      `DTEND:${utcStamp(event.end)}`,
    );
  }
  if (event.rrule) lines.push(`RRULE:${event.rrule}`);
  lines.push(`SUMMARY:${escapeText(event.summary)}`);
  if (event.description) {
    lines.push(`DESCRIPTION:${escapeText(event.description)}`);
  }
  lines.push("END:VEVENT");
  return lines;
}

export function buildCalendar({ name, events, now = new Date() }) {
  const stamp = utcStamp(now);
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//PabLife//Calendario//PT-BR",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    `X-WR-CALNAME:${escapeText(name)}`,
    `X-WR-TIMEZONE:${DEFAULT_TZ}`,
    "REFRESH-INTERVAL;VALUE=DURATION:PT1H",
    "X-PUBLISHED-TTL:PT1H",
    "BEGIN:VTIMEZONE",
    `TZID:${DEFAULT_TZ}`,
    "BEGIN:STANDARD",
    "DTSTART:19700101T000000",
    "TZOFFSETFROM:-0300",
    "TZOFFSETTO:-0300",
    "TZNAME:-03",
    "END:STANDARD",
    "END:VTIMEZONE",
    ...events.flatMap((event) => eventLines(event, stamp)),
    "END:VCALENDAR",
  ];
  return lines.map(foldLine).join("\r\n") + "\r\n";
}

// --------------------------------------------------------------- planner

function allDayEvent(uid, summary, date, description, days = 1) {
  return {
    uid,
    summary,
    description,
    allDay: true,
    start: date,
    end: addDays(date, days),
  };
}

function recurringTask(activity, rule) {
  const timeZone = ruleTimeZone(rule.timezone);
  const days = [...new Set(rule.by_week_day ?? [])]
    .filter((day) => WEEK_DAYS[day] !== undefined);
  if (!rule.start_at || days.length === 0) return null;

  // O primeiro evento precisa cair em um dos dias escolhidos.
  let first = localDate(rule.start_at, timeZone);
  while (!days.includes(weekDayOf(first))) first = addDays(first, 1);

  const event = {
    uid: `activity-${activity.id}`,
    summary: activity.name,
    description: activity.description,
    rrule: `FREQ=WEEKLY;BYDAY=${days.map((day) => WEEK_DAYS[day]).join(",")}`,
  };
  if (activity.all_day) {
    return { ...event, allDay: true, start: first, end: addDays(first, 1) };
  }
  const p = localParts(rule.start_at, timeZone);
  return {
    ...event,
    timeZone,
    minutes: TIMED_TASK_MINUTES,
    localStart: `${compactDate(first)}T${p.hour}${p.minute}${p.second}`,
  };
}

function singleTask(activity, doneIds) {
  const done = doneIds.has(activity.id);
  const summary = `${done ? "✓ " : ""}${activity.name}`;
  const uid = `activity-${activity.id}`;
  if (activity.all_day) {
    return allDayEvent(
      uid,
      summary,
      localDate(activity.due_at, DEFAULT_TZ),
      activity.description,
    );
  }
  const end = new Date(activity.due_at);
  end.setUTCMinutes(end.getUTCMinutes() + TIMED_TASK_MINUTES);
  return {
    uid,
    summary,
    description: activity.description,
    start: activity.due_at,
    end: end.toISOString(),
  };
}

function appointmentEvent(appointment) {
  const start = appointment.start_of_scheduled_window;
  let end = appointment.end_of_scheduled_window;
  if (!end) {
    const fallback = new Date(start);
    fallback.setUTCMinutes(
      fallback.getUTCMinutes() + DEFAULT_APPOINTMENT_MINUTES,
    );
    end = fallback.toISOString();
  }
  const professional = appointment.professional_name;
  return {
    uid: `appointment-${appointment.id}`,
    summary: professional ? `Consulta com ${professional}` : "Consulta",
    start,
    end,
  };
}

export function plannerEvents({
  activities = [],
  appointments = [],
  doneActivityIds = new Set(),
  options = {},
}) {
  const events = [];
  for (const activity of activities) {
    if (activity.type === "goal" && options.include_goals !== false) {
      if (!activity.due_at) continue;
      events.push(
        allDayEvent(
          `activity-${activity.id}`,
          `Meta: ${activity.name}`,
          localDate(activity.due_at, DEFAULT_TZ),
          activity.description,
        ),
      );
    }
    if (activity.type === "task" && options.include_tasks !== false) {
      const rule = activity.rule;
      if (rule) {
        const event = recurringTask(activity, rule);
        if (event) events.push(event);
      } else if (activity.due_at) {
        events.push(singleTask(activity, doneActivityIds));
      }
    }
  }
  if (options.include_appointments !== false) {
    for (const appointment of appointments) {
      events.push(appointmentEvent(appointment));
    }
  }
  return events;
}

// -------------------------------------------------------- saúde da mulher

/** Mesma regra da agenda do app (WomenHealthController._phase). */
function cyclePhase(day, cycleLength) {
  const ovulation = cycleLength - 14;
  if (day <= 5) return "Menstruação";
  if (day === ovulation) return "Ovulação";
  if (day >= ovulation - 5 && day <= ovulation + 1) return "Período fértil";
  return day < ovulation ? "Fase folicular" : "Fase lútea";
}

function cycleEvents(profile, today, discreet) {
  const { last_period: lastPeriod, trail } = profile;
  const cycleLength = profile.cycle_length ?? 28;
  const showAllPhases = trail === "cycle";
  const lastDay = addDays(today, FUTURE_CYCLE_DAYS);
  const events = [];

  let block = null;
  const close = () => {
    if (!block) return;
    const days = daysBetween(block.start, block.end) + 1;
    const estimate = block.phase === "Período fértil" ||
      block.phase === "Ovulação";
    events.push(
      allDayEvent(
        `women-${block.start}-${days}`,
        discreet ? "Ciclo" : block.phase,
        block.start,
        estimate ? FERTILE_NOTICE : "Previsão baseada nas datas informadas.",
        days,
      ),
    );
    block = null;
  };

  for (let offset = 0;; offset++) {
    const date = addDays(lastPeriod, offset);
    if (date > lastDay) break;
    const phase = cyclePhase((offset % cycleLength) + 1, cycleLength);
    const visible = showAllPhases || !phase.startsWith("Fase ");
    if (block && (block.phase !== phase || !visible)) close();
    if (!visible) continue;
    if (block) block.end = date;
    else block = { phase, start: date, end: date };
  }
  close();
  return events;
}

function pregnancyEvents(lastPeriod, discreet) {
  const events = [];
  for (let week = 0; week <= 41; week++) {
    events.push(
      allDayEvent(
        `women-pregnancy-week-${week}-${lastPeriod}`,
        discreet ? `Semana ${week}` : `Semana ${week} da gestação`,
        addDays(lastPeriod, week * 7),
        "Estimativa pela última menstruação. O ultrassom costuma ser mais " +
          "preciso.",
        7,
      ),
    );
  }
  events.push(
    allDayEvent(
      `women-pregnancy-due-${lastPeriod}`,
      discreet ? "Data importante" : "Data provável do parto",
      addDays(lastPeriod, 280),
      "Estimativa pela última menstruação. Confirme com seu pré-natal.",
    ),
  );
  return events;
}

function menopauseEvents(lastPeriod, today, discreet) {
  const events = [];
  for (let month = 1; month <= MAX_MENOPAUSE_MONTHS; month++) {
    const date = addMonths(lastPeriod, month);
    if (month > 12 && date > addMonths(today, 1)) break;
    const label = month === 1 ? "1 mês" : `${month} meses`;
    events.push(
      allDayEvent(
        `women-menopause-${month}-${lastPeriod}`,
        discreet ? "Ciclo" : `${label} sem menstruar`,
        date,
        month === 12
          ? "A menopausa é confirmada após 12 meses seguidos sem menstruar."
          : undefined,
      ),
    );
  }
  return events;
}

/** Eventos da trilha ativa. Sem trilha ou sem data, o calendário fica vazio. */
export function womenHealthEvents({ profile, discreet = false, now = new Date() }) {
  if (!profile?.trail || !profile.consent_at || !profile.last_period) return [];
  const today = localDate(now, DEFAULT_TZ);
  switch (profile.trail) {
    case "cycle":
    case "conceive":
      return cycleEvents(profile, today, discreet);
    case "pregnancy":
      return pregnancyEvents(profile.last_period, discreet);
    case "menopause":
      return menopauseEvents(profile.last_period, today, discreet);
    default:
      return [];
  }
}
