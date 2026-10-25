// Rules about the source itself, checked on every run so a slip cannot reach main.
import { assert } from "./_shared/testassert.ts";

const root = new URL("./", import.meta.url);

async function sourceFiles(dir = root): Promise<URL[]> {
  const out: URL[] = [];
  for await (const e of Deno.readDir(dir)) {
    const u = new URL(e.name + (e.isDirectory ? "/" : ""), dir);
    if (e.isDirectory) out.push(...await sourceFiles(u));
    else if (e.name.endsWith(".ts")) out.push(u);
  }
  return out;
}
const rel = (u: URL) => u.pathname.slice(root.pathname.length);
const isTest = (u: URL) => /(_test|testkit|testutil|testassert)\.ts$/.test(u.pathname);

Deno.test("production code never touches the platform's powerful credentials", async () => {
  const forbidden = [/SUPABASE_DB_URL/, /SERVICE_ROLE/i, /SUPABASE_SERVICE/i, /sb_secret_/, /service_role/];
  for (const u of await sourceFiles()) {
    if (isTest(u)) continue;
    const text = await Deno.readTextFile(u);
    for (const re of forbidden) assert.ok(!re.test(text), `${rel(u)} mentions ${re}`);
  }
});

Deno.test("only log.ts writes to the console, and only services.ts reads the environment", async () => {
  for (const u of await sourceFiles()) {
    if (isTest(u)) continue;
    const text = await Deno.readTextFile(u);
    if (rel(u) !== "_shared/log.ts") {
      assert.ok(!/console\.(log|error|warn|info|debug)/.test(text), `${rel(u)} logs`);
    }
    if (rel(u) !== "_shared/services.ts") assert.ok(!/Deno\.env/.test(text), `${rel(u)} reads env`);
  }
});

Deno.test("every function folder has the standard entry point and a config entry that matches", async () => {
  const names: string[] = [];
  for await (const e of Deno.readDir(root)) {
    if (e.isDirectory && !e.name.startsWith("_")) names.push(e.name);
  }
  assert.ok(names.length >= 6);
  const entry = `import { makeHandler } from "../_shared/handler.ts";
import { realServices } from "../_shared/services.ts";
import { spec } from "./handler.ts";

Deno.serve(makeHandler(spec, realServices));
`;
  const config = await Deno.readTextFile(new URL("../config.toml", import.meta.url));
  for (const name of names) {
    assert.equal(await Deno.readTextFile(new URL(`${name}/index.ts`, root)), entry, `${name}/index.ts`);
    const spec = (await import(`./${name}/handler.ts`)).spec;
    assert.equal(spec.name, name, `${name}: spec name matches the folder`);
    assert.ok(
      new RegExp(`\\[functions\\.${name}\\]\\s*\\nverify_jwt = false`).test(config),
      `${name}: listed in config.toml`,
    );
  }
  const listed = [...config.matchAll(/^\[functions\.([a-z0-9-]+)\]/gm)].map((m) => m[1]).sort();
  assert.deepEqual(listed, [...names].sort(), "config.toml lists exactly the function folders");
});
