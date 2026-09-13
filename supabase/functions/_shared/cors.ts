// Shared CORS headers for browser-originated calls to the edge functions.
//
// Native apps (iOS/Android) don't send an Origin header and ignore CORS
// entirely, so they're unaffected by anything here. Only the Flutter *web*
// build is subject to CORS, so we reflect an allowed origin instead of the
// old blanket "*": localhost/127.0.0.1 for local dev, plus one production web
// origin configured via the ALLOWED_WEB_ORIGIN secret. Any other browser
// origin gets no Access-Control-Allow-Origin header and is blocked by the
// browser.

const BASE: Record<string, string> = {
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};

function isAllowedOrigin(origin: string): boolean {
  const configured = Deno.env.get("ALLOWED_WEB_ORIGIN");
  if (configured && origin === configured) return true;
  try {
    const host = new URL(origin).hostname;
    return host === "localhost" || host === "127.0.0.1";
  } catch {
    return false;
  }
}

/// CORS headers for a request from [origin] (the request's Origin header, which
/// may be null for native callers). Echoes the origin only when allow-listed.
export function corsHeaders(origin: string | null): Record<string, string> {
  if (origin && isAllowedOrigin(origin)) {
    return { ...BASE, "Access-Control-Allow-Origin": origin };
  }
  return { ...BASE };
}
