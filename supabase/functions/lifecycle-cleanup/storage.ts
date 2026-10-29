import { AccessError } from "../photo-access/handler.ts";
import { photoBucket } from "../photo-access/storage.ts";

export function createPrefixCleaner(url: string, key: string, request = fetch) {
  const headers = {
    Authorization: `Bearer ${key}`,
    apikey: key,
    "Content-Type": "application/json",
  };
  return async (prefix: string): Promise<boolean> => {
    // No wildcard, caller-supplied bucket or deletion of the bucket itself.
    if (
      !/^(accounts\/[a-zA-Z0-9_-]+\/|groups\/[a-zA-Z0-9_-]+\/(?:members\/[a-zA-Z0-9_-]+\/|persons\/[a-zA-Z0-9_-]+\/)?)$/
        .test(prefix)
    ) throw new AccessError(400);
    const deadline = Date.now() + 35000;
    let visited = 0;
    async function drain(path: string, depth: number): Promise<boolean> {
      if (depth > 6) throw new AccessError(503);
      while (true) {
        if (Date.now() > deadline || visited > 1000) return false;
        const response = await request(
          `${url}/storage/v1/object/list/${photoBucket}`,
          {
            method: "POST",
            headers,
            body: JSON.stringify({
              prefix: path,
              limit: 100,
              offset: 0,
              sortBy: { column: "name", order: "asc" },
            }),
            redirect: "error",
            signal: AbortSignal.timeout(8000),
          },
        );
        if (!response.ok) throw new AccessError(503);
        const rows = await response.json() as {
          name: string;
          id: string | null;
        }[];
        if (!Array.isArray(rows)) throw new AccessError(503);
        if (rows.length === 0) return true;
        const files: string[] = [];
        for (const row of rows) {
          visited++;
          if (
            typeof row.name !== "string" || !row.name ||
            /[\/\\\x00-\x1f]/.test(row.name) || [".", ".."].includes(row.name)
          ) throw new AccessError(503);
          if (row.id === null) {
            if (!await drain(`${path}${row.name}/`, depth + 1)) return false;
          } else if (typeof row.id === "string") {
            files.push(`${path}${row.name}`);
          } else throw new AccessError(503);
        }
        if (files.length) {
          const deleted = await request(
            `${url}/storage/v1/object/${photoBucket}`,
            {
              method: "DELETE",
              headers,
              body: JSON.stringify({ prefixes: files }),
              redirect: "error",
              signal: AbortSignal.timeout(8000),
            },
          );
          if (!deleted.ok) throw new AccessError(503);
        }
      }
    }
    return drain(prefix, 0);
  };
}
