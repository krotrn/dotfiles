.pragma library

// battery warnings. warned — the lowest level already announced (100 after plugging in or out: nothing announced yet)
// level — what to announce now: "crit" wins over "warn", so a jump from 100% straight to 3% gives one card
function nextWarning(pct, warned, warn, crit) {
    if (pct <= crit && warned > crit) return { level: "crit", warned: crit };
    if (pct <= warn && warned > warn) return { level: "warn", warned: warn };
    return { level: "none", warned };
}

// crit 1…30, warn above crit, at most 50
function clampLevels(warn, crit) {
    const c = Math.max(1, Math.min(30, Math.round(crit)));
    const w = Math.max(c + 1, Math.min(50, Math.round(warn)));
    return { warn: w, crit: c };
}
