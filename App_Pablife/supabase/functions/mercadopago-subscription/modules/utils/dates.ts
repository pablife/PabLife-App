export function calcNextCycleStartDate(
  now: Date,
  frequency: number,
  frequencyType: "months" | "days",
): string {
  const next = new Date(now.getTime());

  if (frequencyType === "months") {
    next.setUTCMonth(next.getUTCMonth() + frequency);
  } else {
    next.setUTCDate(next.getUTCDate() + frequency);
  }

  return next.toISOString();
}

const DAYS_30_MS = 30 * 24 * 60 * 60 * 1000;

export function resolveSubscriptionStartDate(params: {
  now: Date;
  startedAt: Date | null;
  hasFirstPayment: boolean;
  frequency: number;
  frequencyType: "months" | "days";
}): string {
  const baseNow = params.now;

  if (params.hasFirstPayment && params.startedAt) {
    const diff = baseNow.getTime() - params.startedAt.getTime();
    if (diff >= DAYS_30_MS) {
      return baseNow.toISOString();
    }

    return calcNextCycleStartDate(
      params.startedAt,
      params.frequency,
      params.frequencyType,
    );
  }

  const base = params?.startedAt ?? baseNow;
  return calcNextCycleStartDate(base, params.frequency, params.frequencyType);
}
