import type { CreditsSnapshot, RateLimitSnapshot, RateLimitWindow } from "./codexRpc";

function windowLabel(win: RateLimitWindow | null | undefined, fallback: string): string {
  const minutes = win?.windowDurationMins ?? undefined;
  if (minutes === 300) return "5h";
  if (minutes === 10080) return "weekly";
  if (typeof minutes === "number") return `${minutes}m`;
  return fallback;
}

function formatReset(resetsAt?: number | null): string {
  if (!resetsAt) return "";
  const date = new Date(resetsAt * 1000);
  return `, resets at ${date.toISOString()}`;
}

function formatPercent(value?: number): string {
  if (typeof value !== "number" || Number.isNaN(value)) return "unknown";
  const rounded = Math.round(value * 10) / 10;
  return `${rounded}%`;
}

function formatWindow(label: string, win?: RateLimitWindow | null): string {
  if (!win) return `${label}: unavailable`;
  return `${label}: ${formatPercent(win.usedPercent)} used${formatReset(win.resetsAt)}`;
}

function formatCredits(credits?: CreditsSnapshot | null): string | undefined {
  if (!credits) return undefined;
  if (credits.unlimited) return "credits: unlimited";
  if (credits.hasCredits === false) return "credits: none";
  if (credits.balance) return `credits: ${credits.balance}`;
  return "credits: unknown";
}

export function formatRateLimits(snapshot: RateLimitSnapshot): string[] {
  const lines: string[] = [];

  const primaryLabel = windowLabel(snapshot.primary, "primary");
  const secondaryLabel = windowLabel(snapshot.secondary, "secondary");

  if (snapshot.primary || snapshot.secondary) {
    if (snapshot.primary) lines.push(formatWindow(primaryLabel, snapshot.primary));
    if (snapshot.secondary) lines.push(formatWindow(secondaryLabel, snapshot.secondary));
  } else {
    lines.push("limits: unavailable");
  }

  const creditsLine = formatCredits(snapshot.credits);
  if (creditsLine) lines.push(creditsLine);

  return lines;
}

