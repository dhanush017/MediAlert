import { test, after } from "node:test";
import assert from "node:assert/strict";
import pg from "pg";

// Runs the statements as the least-privilege app role. Everything happens inside a transaction
// that is always rolled back, so this test leaves no rows behind.

const DATABASE_URL = process.env.DATABASE_URL;
const skip = DATABASE_URL ? false : "DATABASE_URL not set; see backend/.env";

const pool = DATABASE_URL ? new pg.Pool({ connectionString: DATABASE_URL, max: 2 }) : null;

after(async () => {
  if (pool) await pool.end();
});

async function withAppRole(run: (client: pg.PoolClient) => Promise<void>): Promise<void> {
  const client = await pool!.connect();
  try {
    await client.query("BEGIN");
    await client.query("SET LOCAL ROLE medialert_app");
    await run(client);
  } finally {
    await client.query("ROLLBACK");
    client.release();
  }
}

test("app role can insert into audit_logs", { skip }, async () => {
  await withAppRole(async (client) => {
    const res = await client.query(
      `INSERT INTO audit_logs (action, target_table, source)
       VALUES ('app_role_insert', 'medicines', 'system') RETURNING id`,
    );
    assert.equal(res.rowCount, 1);
  });
});

test("app role can read audit_logs", { skip }, async () => {
  await withAppRole(async (client) => {
    await client.query("SELECT id FROM audit_logs LIMIT 1");
  });
});

test(
  "app role is denied UPDATE on audit_logs by privilege, not only by trigger",
  { skip },
  async () => {
    await withAppRole(async (client) => {
      await client.query("SAVEPOINT before_update");
      await assert.rejects(
        client.query(`UPDATE audit_logs SET action = 'tampered'`),
        /permission denied for table audit_logs/,
      );
      await client.query("ROLLBACK TO SAVEPOINT before_update");
    });
  },
);

test(
  "app role is denied DELETE on audit_logs by privilege, not only by trigger",
  { skip },
  async () => {
    await withAppRole(async (client) => {
      await client.query("SAVEPOINT before_delete");
      await assert.rejects(
        client.query(`DELETE FROM audit_logs`),
        /permission denied for table audit_logs/,
      );
      await client.query("ROLLBACK TO SAVEPOINT before_delete");
    });
  },
);

test("app role is denied TRUNCATE on audit_logs", { skip }, async () => {
  await withAppRole(async (client) => {
    await client.query("SAVEPOINT before_truncate");
    await assert.rejects(
      client.query(`TRUNCATE audit_logs`),
      /permission denied for table audit_logs/,
    );
    await client.query("ROLLBACK TO SAVEPOINT before_truncate");
  });
});
