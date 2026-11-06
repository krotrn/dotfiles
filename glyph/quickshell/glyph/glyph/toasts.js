.pragma library

// per-event toasts: which events show a card in the island by default. Everything here can be switched in Settings or `glyph toast set`
const DEFAULTS = {
    charging: true,
    charged: true,
    game: true,
    dnd: true,
    vpn: true,
    audioIn: true,
    audioOut: false,
    caps: false,
    num: false,
    layout: false,
    config: false,
    nowPlaying: false
};

// stored — the saved overrides (may be null or lack the key: an old rules.json); an unknown key is off
function resolve(stored, key) {
    if (!Object.prototype.hasOwnProperty.call(DEFAULTS, key)) return false;
    if (stored && typeof stored[key] === "boolean") return stored[key];
    return DEFAULTS[key];
}
