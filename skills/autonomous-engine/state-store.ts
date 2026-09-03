import * as fs from "fs";
import * as path from "path";

export function ensureDirectory(directory: string): void {
  fs.mkdirSync(directory, { recursive: true });
}

export function readJson<T>(filePath: string, fallback: T): T {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return fallback;
    throw new Error(`Unable to read ${filePath}: ${String(error)}`);
  }
}

export function writeJsonAtomic(filePath: string, value: unknown): void {
  ensureDirectory(path.dirname(filePath));
  const tempPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  fs.writeFileSync(tempPath, `${JSON.stringify(value, null, 2)}\n`, { encoding: "utf8", mode: 0o600 });
  fs.renameSync(tempPath, filePath);
}

export function appendJsonRecord<T>(filePath: string, value: T, maxEntries = 1_000): void {
  const records = readJson<T[]>(filePath, []);
  records.push(value);
  writeJsonAtomic(filePath, records.slice(-maxEntries));
}
