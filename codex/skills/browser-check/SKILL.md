---
name: browser-check
description: Verify a localhost or other user-specified local web page by checking its rendered browser output through Edge remote debugging rather than only reading source or curl responses. Use when the user asks Codex to confirm what is actually shown in the browser, reproduce a UI bug, inspect visible errors, validate navigation or form behavior, or perform browser-based checks of a local app through an Edge DevTools debugging session.
---

# Browser Check

Verify rendered browser behavior for a local web app.

Treat this skill as a visual/runtime check, not a static code review. Do not claim a page looks correct based only on HTML, network responses, or source inspection.

## Default Browser

Use Windows Edge through DevTools remote debugging as the browser runtime.

- Preferred path: connect to an already-running Edge that was launched with `--remote-debugging-port=<port>`.
- Preferred discovery helper: `scripts/edge-devtools-info.sh [port] [host]`.
- Preferred port: `9222` unless the user specifies another one.
- Expected prerequisite: the DevTools HTTP endpoints such as `/json/version` and `/json/list` must be reachable from the current environment.
- If Edge is not running with remote debugging, say so clearly and describe the missing prerequisite.

Do not assume ordinary Edge sessions are inspectable. Edge is usable only when remote debugging is enabled. Do not fall back to Chromium or another browser runtime unless the user explicitly changes the requirement.

## Recommended Launch

Use a fixed port, normally `9222`. On this machine the common Windows Edge path is:

```powershell
& 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' --remote-debugging-port=9222
```

If you want a clean debugging session, use a dedicated profile directory:

```powershell
& 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' --remote-debugging-port=9222 --user-data-dir="$env:TEMP\edge-debug-9222"
```

From WSL, verify reachability with:

```bash
curl -fsSL http://127.0.0.1:9222/json/version
```

If that endpoint is not reachable, do not claim browser verification through Edge.

## Core Rules

- Check the rendered page in a browser context when the task is about visible UI, navigation, runtime errors, or browser behavior.
- Use localhost or another user-provided local URL as the target. Do not invent a target URL.
- If the app is not already running, start it only when the user asked for browser checking and the start command is discoverable from the repo.
- Prefer reusing the user's existing Edge debugging session over creating a separate browser runtime.
- Report what is actually visible: page text, broken states, missing content, obvious visual regressions, redirects, and form outcomes.
- If Edge DevTools is unavailable, say so clearly. Do not substitute curl-only or source-only inspection as if it were browser verification.

## Workflow

1. Identify the target URL.
2. Determine whether the local app is already running.
3. If needed, discover and run the local dev server.
4. Check whether Edge DevTools is reachable, usually on `127.0.0.1:9222`.
5. Reuse the reachable Edge debugging target.
6. Observe the rendered output and runtime behavior through that Edge debugging session.
7. Summarize concrete findings, including blockers and exact failing steps.

## What To Inspect

Inspect only what the user needs, but default to these checks when the request is broad.

- Initial render: visible headings, empty states, loading loops, hydration failures.
- Navigation: redirects, route changes, broken links, stuck transitions.
- Forms: required fields, submit behavior, inline validation, success/error messages.
- Visual regressions that are obvious in browser output: missing styles, collapsed layout, hidden controls, overlapping text.
- Browser-side failures exposed by the page or by the debugging session.
- Auth-sensitive flows: login result, unauthorized redirects, stale session behavior.

## Reporting

Report the result as browser-observed facts.

- Include the URL checked.
- Include whether the app had to be started or was already running.
- Include the debugging endpoint used when relevant.
- Distinguish between browser-observed behavior and DOM- or source-based inference.
- Quote short visible text snippets when useful.
- If blocked, say exactly what prevented verification: Edge not started with remote debugging, endpoint unreachable, auth unavailable, page crashed before render, and so on.

## Constraints

- Do not overclaim visual verification from non-browser tools.
- Do not assume Playwright or any specific E2E framework exists.
- Do not fall back to Chromium just because it exists on the machine.
- Do not spend time setting up a large E2E harness unless the user asks for that explicitly.
- Do not expand into broad code review unless the browser check exposes a concrete issue that needs follow-up.
