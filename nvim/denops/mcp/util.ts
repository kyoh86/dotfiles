import * as z from "zod";

export function formatZodError(error: z.ZodError) {
  return error.issues.map((issue) => {
    const path = issue.path.length === 0 ? "(root)" : issue.path.join(".");
    return `${path}: ${issue.message}`;
  }).join("; ");
}

export function logError(prefix: string, error: unknown) {
  if (error instanceof z.ZodError) {
    console.error(prefix, formatZodError(error));
    return;
  }
  if (error instanceof Error) {
    console.error(prefix, error.message);
    return;
  }
  console.error(prefix, String(error));
}

export function isTruthy(value: unknown): boolean {
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "number") {
    return value !== 0;
  }
  return Boolean(value);
}
