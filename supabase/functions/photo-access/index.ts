import { verifyFirebaseToken } from "./firebase.ts";
import { createHandler, fetchDocument } from "./handler.ts";
import { createPhotoStorage } from "./storage.ts";

// Standard Supabase server environment, never sent to Flutter or logged.
const url = Deno.env.get("SUPABASE_URL");
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!url || !serviceKey) {
  throw new Error("Missing server storage configuration");
}

Deno.serve(createHandler({
  verifyToken: verifyFirebaseToken,
  fetchDocument,
  storage: createPhotoStorage(url, serviceKey),
}));
