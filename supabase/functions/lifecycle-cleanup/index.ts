import { verifyFirebaseToken } from "../photo-access/firebase.ts";
import { createLifecycleCleanup, readLifecycleDocument } from "./handler.ts";
import { createPrefixCleaner } from "./storage.ts";

const url = Deno.env.get("SUPABASE_URL") ?? "",
  key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
if (url !== "https://ietnizafvtovelyuxbvk.supabase.co" || !key) {
  throw new Error("Photos project configuration required");
}
Deno.serve(
  createLifecycleCleanup({
    verify: verifyFirebaseToken,
    read: readLifecycleDocument,
    removePrefix: createPrefixCleaner(url, key),
  }),
);
