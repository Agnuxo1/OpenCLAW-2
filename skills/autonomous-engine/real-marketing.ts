#!/usr/bin/env node
import { runLiteraryCycle } from "./literary-tasks";

console.warn(
  "real-marketing.ts is deprecated. External actions now pass through Leonardo, verification, and approval.",
);

runLiteraryCycle(Date.now())
  .then((outcome) => console.log(JSON.stringify(outcome, null, 2)))
  .catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
