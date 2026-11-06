import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const ctx = vm.createContext({});
// the QML-only ".pragma library" line is not JavaScript
const src = readFileSync(new URL("../glyph/battery.js", import.meta.url), "utf8").replace(/^\.pragma.*$/m, "");
vm.runInContext(src, ctx);

const next = (...a) => JSON.parse(JSON.stringify(ctx.nextWarning(...a)));
const clamp = (...a) => JSON.parse(JSON.stringify(ctx.clampLevels(...a)));

test("dropping below the warn level warns once", () => {
    assert.deepEqual(next(19, 100, 20, 5), { level: "warn", warned: 20 });
});
test("a jump straight below the critical level gives only the critical result", () => {
    assert.deepEqual(next(3, 100, 20, 5), { level: "crit", warned: 5 });
});
test("an already warned level does not repeat", () => {
    assert.deepEqual(next(18, 20, 20, 5), { level: "none", warned: 20 });
});
test("critical follows a warning", () => {
    assert.deepEqual(next(4, 20, 20, 5), { level: "crit", warned: 5 });
});
test("nothing repeats after the critical warning", () => {
    assert.deepEqual(next(2, 5, 20, 5), { level: "none", warned: 5 });
});
test("above the warn level nothing happens", () => {
    assert.deepEqual(next(60, 100, 20, 5), { level: "none", warned: 100 });
});
test("a reset warned (plugging in) arms the warning again", () => {
    assert.equal(next(19, 100, 20, 5).level, "warn");
});
test("warn is pushed above crit", () => {
    assert.deepEqual(clamp(4, 10), { warn: 11, crit: 10 });
});
test("warn is capped at 50", () => {
    assert.equal(clamp(80, 5).warn, 50);
});
test("crit stays within 1 to 30", () => {
    assert.equal(clamp(40, 0).crit, 1);
    assert.deepEqual(clamp(50, 99), { warn: 50, crit: 30 });
});
test("valid levels are left as they are", () => {
    assert.deepEqual(clamp(30, 10), { warn: 30, crit: 10 });
});
