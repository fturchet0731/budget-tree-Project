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

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-sonnet-4-6";

// Per-user cap on AI calls per rolling hour. Generous for real use (a handful
// of budget/goal plans and the odd reflection) but low enough that an abuser
// with the public anon key can't run up the Anthropic bill.
const HOURLY_CALL_LIMIT = 30;

// Hard caps on the free-form inputs that get embedded into the prompt, so a
// caller can't inflate token cost (and spend) with an enormous payload.
const MAX_EXPENSES = 40;
const MAX_NAME_LEN = 60;
const MAX_SYNOPSIS_LEN = 500;
const MAX_SURVEY_ENTRIES = 20;
const MAX_SURVEY_VALUE_LEN = 120;
// Reflection summaries are assembled by the app from its own rows, but the
// request body is still attacker-controlled, so the payload is rebuilt here
// from an allow-list rather than forwarded verbatim.
const MAX_BUDGETS = 20;
const MAX_LINKED_GOALS = 40;

// Coerce to a finite number, defaulting to 0. Guards against NaN/Infinity and
// strings sneaking into the prompt.
function num(v: unknown): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

// Trim a caller-supplied string to a bounded, single-line value.
function str(v: unknown, max = MAX_NAME_LEN): string {
  return String(v ?? "").slice(0, max);
}

// A bounded array from an unknown value. A non-array (string, object, null)
// becomes empty rather than throwing part-way through building the prompt.
function arr(v: unknown, max: number): unknown[] {
  return Array.isArray(v) ? v.slice(0, max) : [];
}

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
  const income = num(body.income);
  // Both of these land in the system prompt, so they get the same bounding as
  // every other caller-supplied string.
  const currency = str(body.currency || "$", 8);
  const locale = str(body.locale || "en", 16);
  const synopsis = String(body.synopsis ?? "").trim();
  // The budget's cycle: income and every amount are per this period, not
  // necessarily monthly, so estimates must be scaled to it.
  const CYCLES: Record<string, string> = {
    weekly: "week",
    biweekly: "2 weeks",
    semimonthly: "half month",
    monthly: "month",
  };
  // A custom rhythm arrives as `every:3:weeks` (Rhythm.wire). Render it in
  // words for the prompt; anything unrecognised falls back to a month.
  const cycleToken = str(body.cycle || "monthly", 24);
  const custom = /^every:(\d{1,3}):(days|weeks|months)$/.exec(cycleToken);
  const cycle = custom
    ? `${custom[1]} ${custom[1] === "1" ? custom[2].slice(0, -1) : custom[2]}`
    : (CYCLES[cycleToken] ?? "month");
  const synopsisCapped = synopsis.slice(0, MAX_SYNOPSIS_LEN);
  // A small lifestyle questionnaire (question -> chosen answer) the user filled
  // in so the coach can estimate the amounts of expenses left blank. Bounded so
  // an oversized payload can't amplify token cost.
  const survey: Record<string, string> = {};
  for (
    const [k, v] of Object.entries(
      (body.survey as Record<string, string>) ?? {},
    ).slice(0, MAX_SURVEY_ENTRIES)
  ) {
    survey[String(k).slice(0, MAX_SURVEY_VALUE_LEN)] = String(v).slice(
      0,
      MAX_SURVEY_VALUE_LEN,
    );
  }
  // Each expense may carry a fixed amount the user already decided, or 0/absent
  // meaning the coach should choose it. Capped in count and name length.
  const expenses = arr(body.expenses, MAX_EXPENSES).map((e) => {
    const o = (e ?? {}) as Record<string, unknown>;
    return { name: str(o.name), amount: num(o.amount) };
  });

  const system =
    `You are a friendly personal budgeting coach. The user budgets per ${cycle}: their income and every amount below are for one ${cycle}, so scale your estimates to that period. They give that income, a list of expense categories (each with an amount they already decided, or 0 meaning you choose it), answers to a short lifestyle questionnaire, and an optional note on how they want their budget to feel. Produce 2 or 3 distinct allocation plans. ${
      LOCALE_NOTE(locale)
    } Respond with ONLY a JSON object, no prose, of the shape:
{"plans":[{"name":string,"items":[{"name":string,"amount":number}],"leftover":number,"rationale":string}]}
Rules: every input expense MUST appear in every plan's items. If an expense has an amount greater than 0, treat it as fixed and use exactly that amount in every plan; only choose amounts for the expenses left at 0. Use the questionnaire answers to make realistic estimates for those blank expenses (for example household size and dining habits shape a food budget). amount values are whole numbers in ${currency}. For each plan, the sum of all item amounts plus leftover MUST equal exactly ${income}. leftover represents money left for savings or goals. Let the questionnaire answers and the note drive how you weight categories and savings, and give each plan a clear distinct name that reflects a different reading of what they asked for. Keep each rationale to one sentence that ties back to their situation.`;

  const user = JSON.stringify({
    income,
    currency,
    synopsis: synopsisCapped,
    survey,
    expenses,
  });
  const { text } = await callClaude(system, user, 1024);
  const parsed = extractJson<{ plans: unknown[] }>(text);
  if (!Array.isArray(parsed.plans) || parsed.plans.length === 0) {
    throw new Error("Model returned no plans");
  }
  return parsed;
}

// ---- action: goal_plans ---------------------------------------------------

const MAX_GOAL_OPTIONS = 6;

// The app computes every amount and date with GoalPlanMath and sends them in.
// The model's job is to explain them, never to recalculate them: its arithmetic
// used to drift, which meant a date the user had explicitly chosen wasn't
// actually met. Anything numeric it returns is ignored by the client.
async function goalPlans(body: Record<string, unknown>) {
  const raw = (body.goal ?? {}) as Record<string, unknown>;
  const goal = {
    name: str(raw.name),
    target: num(raw.target),
    current: num(raw.current),
    uncapped: raw.uncapped === true,
  };
  const rawDate = String(body.targetDate ?? "");
  const targetDate = /^\d{4}-\d{2}-\d{2}$/.test(rawDate) ? rawDate : "";
  const freeMonthly = num(body.freeMonthly);
  const locale = str(body.locale || "en", 16);
  const byDate = body.mode !== "byAmount";

  const options = arr(body.options, MAX_GOAL_OPTIONS).map((o) => {
    const p = (o ?? {}) as Record<string, unknown>;
    const iso = String(p.isoDate ?? "");
    return {
      cadence: str(p.cadence, 12),
      perWatering: num(p.perWatering),
      ...(/^\d{4}-\d{2}-\d{2}$/.test(iso) ? { isoDate: iso } : {}),
    };
  });

  const shared =
    `You are a savings coach for an app where users "water" a goal by contributing on a repeating cadence. The plans have ALREADY been calculated exactly. Do not recalculate, adjust or second-guess any number: copy each cadence and perWatering back verbatim and write only the wording. ${
      LOCALE_NOTE(locale)
    }`;

  const system = byDate
    ? `${shared} The user picked a completion date and each option below is the exact amount that lands on it at that cadence, so every option costs the same per month and differs only in rhythm. Never say one option is cheaper, faster or better value than another, because it is not. Each rationale must say who that rhythm suits, clearly distinct from the others: weekly for small frequent amounts that track a weekly paycheck, biweekly for lining up with a fortnightly payday, monthly for one transfer you can set and forget. If the implied monthly total is more than the user's free monthly income, say so plainly in the rationale of the first option, and offer 1 to 3 alternativeDates that would be easier. Otherwise return an empty alternativeDates array. Respond with ONLY a JSON object of the shape:
{"plans":[{"cadence":"weekly|biweekly|monthly","perWatering":number,"rationale":string}],"alternativeDates":[{"isoDate":"YYYY-MM-DD","perWatering":number,"note":string}]}
Keep each rationale and note to one sentence.`
    : `${shared} The user has NO deadline in mind. The options are a deliberate progression, ordered gentlest first and built from the least and the most they told us they are willing to put in each time: the first is that floor and takes longest, the second is the midpoint, the third is their ceiling and finishes soonest. Here the options DO genuinely differ in commitment, so compare them: the first rationale should reassure that a small amount still gets there and say roughly when, the second should frame it as the balanced middle, the third should be honest that it is the biggest ask but finishes far sooner. Refer to the finish dates you were given; never invent a different one. If an option's monthly total is more than the user's free monthly income, say so in its rationale. Return an empty alternativeDates array. Respond with ONLY a JSON object of the shape:
{"plans":[{"cadence":"weekly|biweekly|monthly","perWatering":number,"rationale":string}],"alternativeDates":[]}
Keep each rationale to one sentence.`;

  const user = JSON.stringify({
    goal,
    freeMonthly,
    options,
    ...(byDate ? { targetDate } : {}),
  });
  const { text } = await callClaude(system, user, 768);
  return extractJson<{ plans: unknown[]; alternativeDates: unknown[] }>(text);
}

// ---- action: reflection ---------------------------------------------------

// A week/month comparison block, rebuilt with coerced numbers.
function comparison(v: unknown) {
  const c = (v ?? {}) as Record<string, unknown>;
  return {
    current: num(c.current),
    previous: num(c.previous),
    pctChange: c.pctChange == null ? null : num(c.pctChange),
  };
}

async function reflection(body: Record<string, unknown>) {
  const period = body.period === "monthly" ? "monthly" : "weekly";
  const locale = str(body.locale || "en", 16);

  // Allow-listed summary: exactly the shape ReflectionService builds, with
  // every list bounded and every name truncated. Anything else in the body is
  // discarded instead of being forwarded into the prompt.
  const summary = {
    period,
    budgets: arr(body.budgets, MAX_BUDGETS).map((b) => {
      const o = (b ?? {}) as Record<string, unknown>;
      return {
        name: str(o.name),
        income: num(o.income),
        allocated: num(o.allocated),
      };
    }),
    week: comparison(body.week),
    month: comparison(body.month),
    streakWeeks: num(body.streakWeeks),
    linkedGoals: arr(body.linkedGoals, MAX_LINKED_GOALS).map((g) => {
      const o = (g ?? {}) as Record<string, unknown>;
      return {
        name: str(o.name),
        recommendedMonthly: num(o.recommendedMonthly),
        contributedThisPeriod: num(o.contributedThisPeriod),
      };
    }),
  };

  const system =
    `You are an encouraging but honest financial accountability coach for a budgeting app themed around growing trees. Given a ${period} summary of the user's budgets, savings activity, streak, and goals, write a short reflection of 2 to 4 sentences. Name one genuine win, one area where they fell short, and one concrete nudge for the coming ${
      period === "monthly" ? "month" : "week"
    }. ${
      LOCALE_NOTE(locale)
    } Keep the tree metaphor light. Respond with ONLY a JSON object of the shape: {"text":string}`;

  const user = JSON.stringify(summary);
  const { text } = await callClaude(system, user, 400);
  return extractJson<{ text: string }>(text);
}

// ---- router ---------------------------------------------------------------

Deno.serve(async (req) => {
  const cors = corsHeaders(req.headers.get("Origin"));

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  const json = (payload: unknown, status = 200) =>
    new Response(JSON.stringify(payload), {
      status,
      headers: { ...cors, "content-type": "application/json" },
    });

  // Verify the caller is a real signed-in user. The gateway's verify_jwt only
  // proves the JWT is validly signed, which the *public* anon key also is — so
  // we must reject the anon role here. getUser() validates the access token
  // against the auth server and returns the user only for a genuine session.
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!supabaseUrl || !anonKey) {
    console.error("SUPABASE_URL / SUPABASE_ANON_KEY not available");
    return json({ error: "server_misconfigured" }, 500);
  }
  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return json({ error: "unauthorized" }, 401);
  }

  // Per-user hourly quota. The DB function records this call and tells us
  // whether the caller is still under the limit.
  //
  // Called with the **service role** and an explicit user id rather than by the
  // signed-in user against auth.uid(): that lets the function be revoked from
  // `authenticated`, so it isn't reachable at /rest/v1/rpc/check_ai_quota where
  // a user could spend their own quota directly. The id can't be spoofed
  // because it comes from getUser() above, which validated the access token
  // against the auth server — never from the request body.
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceKey) {
    console.error("SUPABASE_SERVICE_ROLE_KEY not available");
    return json({ error: "server_misconfigured" }, 500);
  }
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: underQuota, error: quotaError } = await admin.rpc(
    "check_ai_quota",
    { uid: user.id, max_calls: HOURLY_CALL_LIMIT },
  );
  if (quotaError) {
    console.error("check_ai_quota failed", quotaError);
    return json({ error: "internal_error" }, 500);
  }
  if (underQuota !== true) {
    return json({ error: "rate_limited" }, 429);
  }

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
        return json({ error: "unknown_action" }, 400);
    }
  } catch (e) {
    // Log the full detail server-side; never leak internals to the client.
    console.error(e);
    return json({ error: "internal_error" }, 500);
  }
});
