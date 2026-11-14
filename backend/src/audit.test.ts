import { test, after } from "node:test";
import assert from "node:assert/strict";
import pg from "pg";

const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : "DATABASE_URL not set; see backend/.env";

const pool = DATABASE_URL ? new pg.Pool({ connectionString: DATABASE_URL, max: 2 }) : null;

after(async () => {
  if (pool) await pool.end();
});

test("audit_logs accepts inserts", { skip }, async () => {
  const res = await pool!.query(
    `INSERT INTO audit_logs (action, target_table, source, new_state)
     VALUES ('test_insert', 'medicines', 'system', '{"name":"test"}')
     RETURNING id`,
  );
  assert.equal(res.rowCount, 1);
});

test("audit_logs rejects UPDATE", { skip }, async () => {
  const inserted = await pool!.query(
    `INSERT INTO audit_logs (action, target_table, source)
     VALUES ('test_update_target', 'medicines', 'system') RETURNING id`,
  );
  const id = inserted.rows[0].id as string;

  await assert.rejects(
    pool!.query(`UPDATE audit_logs SET action = 'tampered' WHERE id = $1`, [id]),
    /append-only/,
  );
});

test("audit_logs rejects DELETE", { skip }, async () => {
  const inserted = await pool!.query(
    `INSERT INTO audit_logs (action, target_table, source)
     VALUES ('test_delete_target', 'medicines', 'system') RETURNING id`,
  );
  const id = inserted.rows[0].id as string;

  await assert.rejects(pool!.query(`DELETE FROM audit_logs WHERE id = $1`, [id]), /append-only/);
});
