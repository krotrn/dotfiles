.pragma library

// "#RRGGBB" in upper case, or "" for anything else (named colours, short hex, no #)
function normaliseHex(s) {
    return typeof s === "string" && /^#[0-9a-fA-F]{6}$/.test(s) ? s.toUpperCase() : "";
}
