import { AccessError } from "./handler.ts";

export const photoBucket = "boteparroquial-photos";

export function createPhotoStorage(url: string, serviceKey: string) {
  const headers = {
    Authorization: `Bearer ${serviceKey}`,
    apikey: serviceKey,
  };
  const base = `${url}/storage/v1/object/${photoBucket}`;
  async function requireSuccess(response: Response, reading = false) {
    if (reading && response.status === 304) return;
    if (reading && (response.status === 400 || response.status === 404)) {
      // Storage uses 400 for some ObjectNotFound responses; distinguish config
      // or other failures rather than hiding every 400 as an absent image.
      const body = await response.clone().json().catch(() => ({}));
      if (
        body.code === "NoSuchKey" || body.error === "not_found" ||
        body.message === "Object not found"
      ) throw new AccessError(404);
    }
    if (!response.ok) throw new AccessError(503);
  }
  return {
    async upload(path: string, bytes: Uint8Array, contentType: string) {
      const response = await fetch(`${base}/${path}`, {
        method: "POST",
        headers: {
          ...headers,
          "Content-Type": contentType,
          "x-upsert": "true",
        },
        body: new Blob([bytes as Uint8Array<ArrayBuffer>]),
        signal: AbortSignal.timeout(15000),
        redirect: "error",
      });
      await requireSuccess(response);
    },
    async download(path: string, version?: string): Promise<Response> {
      const response = await fetch(`${base}/${path}`, {
        headers: {
          ...headers,
          ...(version ? { "If-None-Match": version } : {}),
        },
        signal: AbortSignal.timeout(15000),
        redirect: "error",
      });
      await requireSuccess(response, true);
      return response;
    },
    async remove(path: string) {
      const response = await fetch(base, {
        method: "DELETE",
        headers: { ...headers, "Content-Type": "application/json" },
        // Storage accepts the decoded object key in its JSON body.
        body: JSON.stringify({ prefixes: [decodeURIComponent(path)] }),
        signal: AbortSignal.timeout(15000),
        redirect: "error",
      });
      await requireSuccess(response);
    },
  };
}
