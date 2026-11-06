.pragma library

// the launcher's actions mode: a query that starts with ">" is a search over the actions; term is what follows, trimmed and lower-cased
function parseActionQuery(q) {
    const t = q.trim();
    if (t.startsWith(">")) return { active: true, term: t.slice(1).trim().toLowerCase() };
    return { active: false, term: t.toLowerCase() };
}
