// Shared CORS headers for browser-originated calls to the edge functions.
// The Flutter app on web sends a preflight OPTIONS request; native does not,
// but returning these everywhere is harmless and keeps web working.
export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
