import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const ctx = vm.createContext({});
// the QML-only ".pragma library" line is not JavaScript
const src = readFileSync(new URL("../launcher/actions.js", import.meta.url), "utf8").replace(/^\.pragma.*$/m, "");
vm.runInContext(src, ctx);
const parse = q => JSON.parse(JSON.stringify(ctx.parseActionQuery(q)));

test("a query starting with > is an action query", () => {
    assert.deepEqual(parse(">light"), { active: true, term: "light" });
});
test("spaces around the > and the term are dropped, the term is lower-cased", () => {
    assert.deepEqual(parse("  > re "), { active: true, term: "re" });
    assert.deepEqual(parse(">Light"), { active: true, term: "light" });
});
test("a plain query is not an action query", () => {
    assert.deepEqual(parse("kitty"), { active: false, term: "kitty" });
});
test("a lone > is active with an empty term", () => {
    assert.deepEqual(parse(">"), { active: true, term: "" });
});
