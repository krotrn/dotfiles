import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";

const ctx = vm.createContext({});
// the QML-only ".pragma library" line is not JavaScript
const src = readFileSync(new URL("../glyph/colour.js", import.meta.url), "utf8").replace(/^\.pragma.*$/m, "");
vm.runInContext(src, ctx);
const norm = s => ctx.normaliseHex(s);

test("a six-digit hex is upper-cased", () => {
    assert.equal(norm("#3a7bd5"), "#3A7BD5");
    assert.equal(norm("#3A7BD5"), "#3A7BD5");
});
test("named colours, short hex, a missing # and stray text are refused", () => {
    for (const s of ["red", "#fff", "3A7BD5", "#3A7BD", "#3A7BD55", "#GGGGGG", " #3A7BD5", "#3A7BD5\n", "", "#"])
        assert.equal(norm(s), "", s);
});
test("non-strings are refused", () => {
    assert.equal(norm(undefined), "");
    assert.equal(norm(null), "");
    assert.equal(norm(123456), "");
});
