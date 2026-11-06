import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const ctx = vm.createContext({});
// the QML-only ".pragma library" line is not JavaScript
const src = readFileSync(new URL("../glyph/toasts.js", import.meta.url), "utf8").replace(/^\.pragma.*$/m, "");
vm.runInContext(src, ctx);

test("a missing store falls back to the default", () => {
    assert.equal(ctx.resolve(null, "charging"), true);
});
test("a key that is off by default stays off when the store is empty", () => {
    assert.equal(ctx.resolve({}, "nowPlaying"), false);
});
test("a stored value wins over the default", () => {
    assert.equal(ctx.resolve({ charging: false }, "charging"), false);
});
test("an unknown key is off", () => {
    assert.equal(ctx.resolve({}, "bogus"), false);
});
