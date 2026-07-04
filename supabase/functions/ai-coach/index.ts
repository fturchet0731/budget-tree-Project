// AI Coaching edge function for Budget Tree.
//
// One function, switched on `action`, that turns the app's already-computed
// summaries into (a) budget allocation plans, (b) goal contribution plans, and
// (c) a short reflection summary. The Anthropic key never leaves the server:
// it is read from the `ANTHROPIC_API_KEY` secret. The app calls this via
// `supabase.functions.invoke('ai-coach', { body: { action, ... } })`.
//
// Deploy:  supabase functions deploy ai-coach
// Secret:  supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//
// Model is pinned to Sonnet per project constraint ("no more than Sonnet").

import { corsHeaders } from "../_shared/cors.ts";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-sonnet-4-6";

interface ClaudeResult {
  text: string;
}

// Call Claude's Messages API with a system + single user turn and return the
// concatenated text. Throws on transport / API errors.
async function callClaude(
  system: string,
  user: string,
  maxTokens: number,
): Promise<ClaudeResult> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) throw new Error("ANTHROPIC_API_KEY is not set");

  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: maxTokens,
      temperature: 0.4,
      system,
      messages: [{ role: "user", content: user }],
    }),
  });

  if (!res.ok) {
    const detail = await res.text();
    throw new Error(`Anthropic ${res.status}: ${detail}`);
  }

  const data = await res.json();
  const text = (data?.content ?? [])
    .filter((b: { type: string }) => b.type === "text")
    .map((b: { text: string }) => b.text)
    .join("")
    .trim();
  return { text };
}

// Models sometimes wrap JSON in prose or fences despite instructions. Pull the
// first balanced JSON object out of the text and parse it.
function extractJson<T>(text: string): T {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  const candidate = fenced ? fenced[1] : text;
  const start = candidate.indexOf("{");
  const end = candidate.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    throw new Error("No JSON object in model output");
  }
  return JSON.parse(candidate.slice(start, end + 1)) as T;
}

const LOCALE_NOTE = (locale: string) =>
  `Write all human-readable text (plan names, rationales, notes, prose) in the language with code "${locale}". Use plain language. Never use em dashes or hyphens to join clauses; write short sentences instead.`;

// ---- action: budget_plans -------------------------------------------------

async function budgetPlans(body: Record<string, unknown>) {
  const income = Number(body.income) || 0;
  const currency = String(body.currency ?? "$");
  const locale = String(body.locale ?? "en");
  const synopsis = String(body.synopsis ?? "").trim();
  // The budget's cycle: income and every amount are per this period, not
  // necessarily monthly, so estimates must be scaled to it.
  const CYCLES: Record<string, string> = {
    weekly: "week",
    biweekly: "2 weeks",
    semimonthly: "half month",
    monthly: "month",
  };
  const cycle = CYCLES[String(body.cycle ?? "monthly")] ?? "month";
  // A small lifestyle questionnaire (question -> chosen answer) the user filled
  // in so the coach can estimate the amounts of expenses left blank.
  const survey = (body.survey as Record<string, string>) ?? {};
  // Each expense may carry a fixed amount the user already decided, or 0/absent
  // meaning the coach should choose it.
  const expenses =
    (body.expenses as Array<{ name: string; amount?: number }>) ?? [];

  const system =
    `You are a friendly personal budgeting coach. The user budgets per ${cycle}: their income and every amount below are for one ${cycle}, so scale your estimates to that period. They give that income, a list of expense categories (each with an amount they already decided, or 0 meaning you choose it), answers to a short lifestyle questionnaire, and an optional note on how they want their budget to feel. Produce 2 or 3 distinct allocation plans. ${
      LOCALE_NOTE(locale)
    } Respond with ONLY a JSON object, no prose, of the shape:
{"plans":[{"name":string,"items":[{"name":string,"amount":number}],"leftover":number,"rationale":string}]}
Rules: every input expense MUST appear in every plan's items. If an expense has an amount greater than 0, treat it as fixed and use exactly that amount in every plan; only choose amounts for the expenses left at 0. Use the questionnaire answers to make realistic estimates for those blank expenses (for example household size and dining habits shape a food budget). amount values are whole numbers in ${currency}. For each plan, the sum of all item amounts plus leftover MUST equal exactly ${income}. leftover represents money left for savings or goals. Let the questionnaire answers and the note drive how you weight categories and savings, and give each plan a clear distinct name that reflects a different reading of what they asked for. Keep each rationale to one sentence that ties back to their situation.`;

  const user = JSON.stringify({ income, currency, synopsis, survey, expenses });
  const { text } = await callClaude(system, user, 1024);
  const parsed = extractJson<{ plans: unknown[] }>(text);
  if (!Array.isArray(parsed.plans) || parsed.plans.length === 0) {
    throw new Error("Model returned no plans");
  }
  return parsed;
}

// ---- action: goal_plans ---------------------------------------------------

async function goalPlans(body: Record<string, unknown>) {
  const goal = body.goal as {
    name: string;
    target: number;
    current: number;
    uncapped: boolean;
  };
  const targetDate = String(body.targetDate ?? "");
  const freeMonthly = Number(body.freeMonthly) || 0;
  const locale = String(body.locale ?? "en");

  const system =
    `You are a savings coach for an app where users "water" a goal by contributing on a repeating cadence. Given a goal (target amount, amount already saved, desired completion date) and the user's estimated free monthly income, produce 2 or 3 distinct watering plans to reach the goal by the target date, plus 1 to 3 alternative completion dates that fit comfortably within the free monthly income. ${
      LOCALE_NOTE(locale)
    } Respond with ONLY a JSON object of the shape:
{"plans":[{"cadence":"weekly|biweekly|monthly","perWatering":number,"monthsToTarget":number,"rationale":string}],"alternativeDates":[{"isoDate":"YYYY-MM-DD","cadence":"weekly|biweekly|monthly","perWatering":number,"note":string}]}
Rules: cadence is exactly one of "weekly", "biweekly", or "monthly". perWatering is the whole-number amount contributed each time at that cadence. Offer a range of cadences across the plans so the user can pick what fits their rhythm. If the contribution needed to hit the target date exceeds the free monthly income, say so in the rationale and lean on the alternative dates. Keep each rationale and note to one sentence.`;

  const user = JSON.stringify({ goal, targetDate, freeMonthly });
  const { text } = await callClaude(system, user, 768);
  return extractJson<{ plans: unknown[]; alternativeDates: unknown[] }>(text);
}

// ---- action: reflection ---------------------------------------------------

async function reflection(body: Record<string, unknown>) {
  const period = String(body.period ?? "weekly");
  const locale = String(body.locale ?? "en");

  const system =
    `You are an encouraging but honest financial accountability coach for a budgeting app themed around growing trees. Given a ${period} summary of the user's budgets, savings activity, streak, and goals, write a short reflection of 2 to 4 sentences. Name one genuine win, one area where they fell short, and one concrete nudge for the coming ${
      period === "monthly" ? "month" : "week"
    }. ${
      LOCALE_NOTE(locale)
    } Keep the tree metaphor light. Respond with ONLY a JSON object of the shape: {"text":string}`;

  const user = JSON.stringify(body);
  const { text } = await callClaude(system, user, 400);
  return extractJson<{ text: string }>(text);
}

// ---- router ---------------------------------------------------------------

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const json = (payload: unknown, status = 200) =>
    new Response(JSON.stringify(payload), {
      status,
      headers: { ...corsHeaders, "content-type": "application/json" },
    });

  try {
    const body = await req.json();
    const action = String(body.action ?? "");
    switch (action) {
      case "budget_plans":
        return json(await budgetPlans(body));
      case "goal_plans":
        return json(await goalPlans(body));
      case "reflection":
        return json(await reflection(body));
      default:
        return json({ error: `Unknown action: ${action}` }, 400);
    }
  } catch (e) {
    console.error(e);
    return json({ error: String(e instanceof Error ? e.message : e) }, 500);
  }
});
