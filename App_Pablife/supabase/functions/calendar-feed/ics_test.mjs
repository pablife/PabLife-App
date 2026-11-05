// Rodar com: node --test supabase/functions/calendar-feed/ics_test.mjs
import assert from "node:assert/strict";
import { test } from "node:test";

import {
  buildCalendar,
  FERTILE_NOTICE,
  plannerEvents,
  womenHealthEvents,
} from "./ics.js";

const now = new Date("2026-11-05T15:00:00Z");
const summaries = (events) => events.map((event) => event.summary);

test("tarefa com horário guarda o instante certo e dura 30 minutos", () => {
  const [event] = plannerEvents({
    activities: [{
      id: "t1",
      type: "task",
      name: "Treino",
      due_at: "2026-11-06T11:00:00+00:00",
      all_day: false,
    }],
  });
  const ics = buildCalendar({ name: "PabLife", events: [event], now });
  assert.match(ics, /DTSTART:20261106T110000Z/);
  assert.match(ics, /DTEND:20261106T113000Z/);
});

test("tarefa feita aparece com o sinal de concluída", () => {
  const [event] = plannerEvents({
    activities: [{
      id: "t1",
      type: "task",
      name: "Treino",
      due_at: "2026-11-06T11:00:00Z",
    }],
    doneActivityIds: new Set(["t1"]),
  });
  assert.equal(event.summary, "✓ Treino");
});

test("tarefa repetida usa os dias do app (0 = domingo) e o horário local", () => {
  const [event] = plannerEvents({
    activities: [{
      id: "t2",
      type: "task",
      name: "Caminhada",
      all_day: false,
      rule: {
        // Quinta 05/11 às 05h em São Paulo; a regra só vale seg, qua e sex.
        start_at: "2026-11-05T08:00:00Z",
        by_week_day: [1, 3, 5],
        timezone: "America/Sao_Paulo",
      },
    }],
  });
  assert.equal(event.rrule, "FREQ=WEEKLY;BYDAY=MO,WE,FR");
  assert.equal(event.localStart, "20261106T050000");
  assert.match(
    buildCalendar({ name: "x", events: [event], now }),
    /DTSTART;TZID=America\/Sao_Paulo:20261106T050000/,
  );
});

test("tarefa repetida de dia inteiro não muda de dia por causa do fuso", () => {
  const [event] = plannerEvents({
    activities: [{
      id: "t3",
      type: "task",
      name: "Água",
      all_day: true,
      rule: {
        start_at: "2026-11-05T03:09:00Z",
        by_week_day: [0, 1, 2, 3, 4, 5, 6],
        timezone: "UTC",
      },
    }],
  });
  assert.equal(event.start, "2026-11-05");
  assert.equal(event.end, "2026-11-06");
});

test("meta vira evento de dia inteiro no dia local", () => {
  const [event] = plannerEvents({
    activities: [{
      id: "g1",
      type: "goal",
      name: "2 L de água",
      due_at: "2026-11-07T02:59:00Z",
    }],
  });
  assert.equal(event.summary, "Meta: 2 L de água");
  assert.equal(event.start, "2026-11-06");
});

test("consulta mostra o profissional", () => {
  const [event] = plannerEvents({
    appointments: [{
      id: "a1",
      start_of_scheduled_window: "2026-11-09T11:00:00Z",
      end_of_scheduled_window: "2026-11-09T12:00:00Z",
      professional_name: "Ana",
    }],
  });
  assert.equal(event.summary, "Consulta com Ana");
});

test("opções desligadas ficam de fora, e nota nunca entra", () => {
  const events = plannerEvents({
    activities: [
      { id: "1", type: "task", name: "T", due_at: "2026-11-06T11:00:00Z" },
      { id: "2", type: "goal", name: "M", due_at: "2026-11-06T11:00:00Z" },
      { id: "3", type: "note", name: "N", due_at: "2026-11-06T11:00:00Z" },
    ],
    appointments: [{
      id: "4",
      start_of_scheduled_window: "2026-11-09T11:00:00Z",
    }],
    options: {
      include_tasks: true,
      include_goals: false,
      include_appointments: false,
    },
  });
  assert.deepEqual(summaries(events), ["T"]);
});

const cycle = {
  trail: "cycle",
  last_period: "2026-10-01",
  cycle_length: 28,
  consent_at: "2026-10-01T00:00:00Z",
};

test("ciclo segue as fases da agenda do app", () => {
  const events = womenHealthEvents({ profile: cycle, now });
  const first = events.slice(0, 7).map((e) => [e.summary, e.start, e.end]);
  assert.deepEqual(first, [
    ["Menstruação", "2026-10-01", "2026-10-06"],
    ["Fase folicular", "2026-10-06", "2026-10-09"],
    ["Período fértil", "2026-10-09", "2026-10-14"],
    ["Ovulação", "2026-10-14", "2026-10-15"],
    ["Período fértil", "2026-10-15", "2026-10-16"],
    ["Fase lútea", "2026-10-16", "2026-10-29"],
    ["Menstruação", "2026-10-29", "2026-11-03"],
  ]);
});

test("dias férteis levam o aviso de estimativa", () => {
  const fertile = womenHealthEvents({ profile: cycle, now })
    .find((event) => event.summary === "Período fértil");
  assert.equal(fertile.description, FERTILE_NOTICE);
});

test("ciclo prevê cerca de um ano à frente", () => {
  const events = womenHealthEvents({ profile: cycle, now });
  assert.ok(events.at(-1).start >= "2027-10-01");
  assert.ok(events.at(-1).start <= "2027-11-05");
});

test("quero gestar não mostra fase folicular nem lútea", () => {
  const events = womenHealthEvents({
    profile: { ...cycle, trail: "conceive" },
    now,
  });
  assert.deepEqual(
    [...new Set(summaries(events))].sort(),
    ["Menstruação", "Ovulação", "Período fértil"],
  );
});

test("modo discreto não mostra o nome das fases", () => {
  const events = womenHealthEvents({ profile: cycle, discreet: true, now });
  assert.deepEqual([...new Set(summaries(events))], ["Ciclo"]);
});

test("gestação mostra semanas e data provável do parto", () => {
  const events = womenHealthEvents({
    profile: { ...cycle, trail: "pregnancy" },
    now,
  });
  assert.equal(events[12].summary, "Semana 12 da gestação");
  assert.equal(events[12].start, "2026-12-24");
  const due = events.find((e) => e.summary === "Data provável do parto");
  assert.equal(due.start, "2027-07-08");
});

test("menopausa conta os meses e marca os 12 meses", () => {
  const events = womenHealthEvents({
    profile: { ...cycle, trail: "menopause", last_period: "2026-01-31" },
    now,
  });
  assert.equal(events[0].summary, "1 mês sem menstruar");
  assert.equal(events[0].start, "2026-02-28");
  assert.equal(events[11].summary, "12 meses sem menstruar");
  assert.match(events[11].description, /12 meses seguidos/);
});

test("sem trilha, sem aceite ou sem data, o calendário fica vazio", () => {
  assert.deepEqual(womenHealthEvents({ profile: null, now }), []);
  assert.deepEqual(
    womenHealthEvents({ profile: { ...cycle, trail: null }, now }),
    [],
  );
  assert.deepEqual(
    womenHealthEvents({ profile: { ...cycle, consent_at: null }, now }),
    [],
  );
  assert.deepEqual(
    womenHealthEvents({ profile: { ...cycle, last_period: null }, now }),
    [],
  );
});

test("arquivo usa CRLF, escapa texto e corta linhas em 75 bytes", () => {
  const ics = buildCalendar({
    name: "PabLife",
    events: [{
      uid: "x",
      summary: "Menstruação, dia; com \\ e\nquebra " + "á".repeat(60),
      allDay: true,
      start: "2026-11-05",
      end: "2026-11-06",
    }],
    now,
  });
  assert.ok(ics.startsWith("BEGIN:VCALENDAR\r\n"));
  assert.ok(ics.endsWith("END:VCALENDAR\r\n"));
  assert.ok(!/[^\r]\n/.test(ics));
  assert.match(ics, /Menstruação\\, dia\\; com \\\\ e\\nquebra/);
  const encoder = new TextEncoder();
  for (const line of ics.split("\r\n")) {
    assert.ok(encoder.encode(line).length <= 75, line);
  }
});
