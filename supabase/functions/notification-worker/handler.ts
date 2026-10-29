import { WorkerError } from "../_shared/server_firestore.ts";

export function createWorkerHandler(
  secret: string,
  run: () => Promise<unknown>,
) {
  if (secret.length < 40) throw new Error("invalid_worker_secret");
  const encoder = new TextEncoder();
  const hash = (value: string) =>
    crypto.subtle.digest("SHA-256", encoder.encode(value));
  return async (request: Request) => {
    const supplied = request.headers.get("x-worker-secret") ?? "";
    const expected = new Uint8Array(await hash(secret));
    const actual = new Uint8Array(await hash(supplied));
    let difference = supplied.length > 256 ? 1 : 0;
    for (let i = 0; i < expected.length; i++) {
      difference |= expected[i] ^ actual[i];
    }
    if (request.method !== "POST" || difference !== 0) {
      return Response.json({ error: "unauthorized" }, { status: 401 });
    }
    // No client-selected group, recipients, amounts, credential or date in body.
    if ((await request.text()).trim() !== "{}") {
      return Response.json({ error: "invalid_request" }, { status: 400 });
    }
    try {
      return Response.json(await run());
    } catch (error) {
      return Response.json({
        error: "worker_failed",
        code: error instanceof WorkerError ? error.code : "unexpected",
        status: error instanceof WorkerError ? error.status : null,
      }, { status: 503 });
    }
  };
}
