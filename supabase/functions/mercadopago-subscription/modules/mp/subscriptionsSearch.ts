import { MpClient } from "./mpClient.ts";

type MpPreapprovalSearchItem = {
  id?: string;
  status?: string;
  external_reference?: string;
  date_created?: string;
  auto_recurring?: {
    start_date?: string;
  };
};

type MpPreapprovalSearchResponse = {
  results?: MpPreapprovalSearchItem[];
};

export type AuthorizedSubscriptionMatch = {
  id: string;
  status: string;
  start_date?: string;
};

function extractResults(
  response: MpPreapprovalSearchResponse | MpPreapprovalSearchItem[] | unknown,
): MpPreapprovalSearchItem[] {
  if (!response) return [];
  if (Array.isArray(response)) return response as MpPreapprovalSearchItem[];
  if (typeof response === "object" && response !== null) {
    const record = response as MpPreapprovalSearchResponse;
    if (Array.isArray(record.results)) return record.results;
  }
  return [];
}

function pickMostRecent(
  items: MpPreapprovalSearchItem[],
): MpPreapprovalSearchItem | null {
  if (items.length === 0) return null;
  return items.reduce((latest, current) => {
    const latestTime = Date.parse(latest.date_created ?? "") || 0;
    const currentTime = Date.parse(current.date_created ?? "") || 0;
    return currentTime > latestTime ? current : latest;
  });
}

async function searchPreapprovals(
  client: MpClient,
  params: { payer_email: string; preapproval_plan_id?: string },
): Promise<MpPreapprovalSearchItem[]> {
  const query = new URLSearchParams();
  query.set("payer_email", params.payer_email);
  if (params.preapproval_plan_id) {
    query.set("preapproval_plan_id", params.preapproval_plan_id);
  }

  const response = await client.request<MpPreapprovalSearchResponse>(
    `/preapproval/search?${query.toString()}`,
    { method: "GET" },
  );

  return extractResults(response);
}

export async function findAuthorizedSubscription(params: {
  client: MpClient;
  payer_email: string;
  preapproval_plan_id?: string;
  external_reference: string;
}): Promise<AuthorizedSubscriptionMatch | null> {
  let results: MpPreapprovalSearchItem[] = [];

  try {
    results = await searchPreapprovals(params.client, {
      payer_email: params.payer_email,
      preapproval_plan_id: params.preapproval_plan_id,
    });
  } catch {
    results = await searchPreapprovals(params.client, {
      payer_email: params.payer_email,
    });
  }

  const matches = results.filter((item) =>
    item.id &&
    item.status === "authorized" &&
    item.external_reference === params.external_reference
  );

  const selected = pickMostRecent(matches);
  if (!selected || !selected.id) return null;

  return {
    id: selected.id,
    status: selected.status ?? "authorized",
    start_date: selected.auto_recurring?.start_date,
  };
}
