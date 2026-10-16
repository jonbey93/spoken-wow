"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import type { CombatRecording } from "@/lib/combat/recordings";

export default function CombatRecordings({ lines }: { lines: CombatRecording[] }) {
  const router = useRouter();
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState("");
  async function generate(lineId: string) {
    setBusy(lineId); setError("");
    try {
      const response = await fetch("/api/combat/regenerate?lang=enUS", {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ lineId }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error ?? "Generation failed");
      router.refresh();
    } catch (error) { setError(error instanceof Error ? error.message : "Generation failed"); }
    finally { setBusy(null); }
  }
  return <div className="space-y-6">
    {error && <p role="alert" className="text-destructive">{error}</p>}
    <ol className="divide-y rounded-lg border px-4">
      {lines.map((line) => <li key={line.id} className="flex flex-wrap items-center gap-4 py-4">
        <div className="min-w-48 flex-1">
          <p>{line.key}. {line.text}</p>
          <p className="text-muted-foreground text-sm">{line.version === null ? "Not recorded" :
            line.stale ? "Text changed: regenerate before packaging" :
            line.duration === null ? "Duration unavailable: regenerate" :
            `${line.duration.toFixed(1)}s${line.duration > 6 ? ": too long, regenerate" : ""}`}</p>
        </div>
        {line.version !== null && <audio controls preload="none" className="h-9 max-w-full" key={`${line.id}:${line.version}`}
          src={`/api/takes/audio?source=quests&lang=enUS&file=${encodeURIComponent(line.file)}&version=${line.version}`} />}
        <Button disabled={busy !== null} onClick={() => generate(line.id)}>
          {busy === line.id ? "Generating…" : line.version === null ? "Generate" : "Regenerate"}
        </Button>
      </li>)}
    </ol>
    {lines.every((line) => line.ready) ?
      <Button asChild><a href="/api/combat/package?lang=enUS">Download Spoken Combat Audio</a></Button> :
      <p className="text-muted-foreground">The download becomes available when all {lines.length} lines have current recordings of at most 6 seconds.</p>}
    <p className="text-sm">Install the updated Spoken addon first. Close WoW and extract SpokenCombatAudio into
      Interface/AddOns as its own folder, then start the game. Under Spoken → Combat, enable the module
      and use Preview Combat Voice, or type /spoken combat test.</p>
  </div>;
}
