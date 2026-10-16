import data from "./lines.json";

export const COMBAT_VOICE = data.voice;
export const COMBAT_LINES = data.lines.map((line) => ({
  ...line,
  id: `c:${COMBAT_VOICE}:${line.key}`,
  file: `combat/${COMBAT_VOICE}-${line.key}.mp3`,
}));

export function combatLine(id: string) {
  return COMBAT_LINES.find((line) => line.id === id);
}

export function isCombatFile(file: string): boolean {
  return COMBAT_LINES.some((line) => line.file === file);
}
