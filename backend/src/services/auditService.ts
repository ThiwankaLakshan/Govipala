import { PoolClient } from 'pg';
import { query } from '../db';

export interface AuditLogEntry {
  id: string;
  admin_id: string;
  admin_name?: string;
  action: string;
  target_table: string;
  target_id: string | null;
  before_data: any;
  after_data: any;
  reason: string | null;
  created_at: Date;
}

export interface CreateAuditLogParams {
  client?: PoolClient;
  admin_id: string;
  admin_name?: string;
  action: string;
  target_table: string;
  target_id?: string | null;
  before_data?: any;
  after_data?: any;
  reason?: string | null;
}

// In-memory audit log storage for dev/testing when PostgreSQL is offline
export const devAuditLogs: AuditLogEntry[] = [
  {
    id: 'a0000000-0000-0000-0000-000000000001',
    admin_id: '99999999-0000-0000-0000-000000000001',
    admin_name: 'Admin User',
    action: 'CREATE_USER',
    target_table: 'users',
    target_id: '11111111-0000-0000-0000-000000000001',
    before_data: null,
    after_data: { full_name: 'සුනිල් පෙරේරා (Sunil Perera)', role: 'both', status: 'active' },
    reason: 'Initial system provisioning for Padaviya pilot',
    created_at: new Date('2026-11-20T08:00:00Z'),
  },
  {
    id: 'a0000000-0000-0000-0000-000000000002',
    admin_id: '99999999-0000-0000-0000-000000000001',
    admin_name: 'Admin User',
    action: 'CREATE_MACHINE',
    target_table: 'machines',
    target_id: '10000000-0000-0000-0000-000000000001',
    before_data: null,
    after_data: { brand: 'Massey Ferguson', model: '240 Di', machine_type: 'four_wheel_tractor', drive_type: '4wd' },
    reason: 'Assisted owner onboarding via phone',
    created_at: new Date('2026-11-20T09:30:00Z'),
  },
];

export async function logAdminAction(params: CreateAuditLogParams): Promise<AuditLogEntry> {
  const {
    client,
    admin_id,
    admin_name,
    action,
    target_table,
    target_id = null,
    before_data = null,
    after_data = null,
    reason = null,
  } = params;

  try {
    const sql = `
      INSERT INTO admin_audit_log (
        admin_id,
        action,
        target_table,
        target_id,
        before_data,
        after_data,
        reason
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `;

    const values = [
      admin_id,
      action,
      target_table,
      target_id,
      before_data ? JSON.stringify(before_data) : null,
      after_data ? JSON.stringify(after_data) : null,
      reason,
    ];

    const result = client ? await client.query(sql, values) : await query(sql, values);
    return result.rows[0];
  } catch (err: any) {
    // If PostgreSQL is not connected, log in dev array
    const entry: AuditLogEntry = {
      id: `dev-audit-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      admin_id,
      admin_name: admin_name || 'Admin',
      action,
      target_table,
      target_id: target_id || null,
      before_data,
      after_data,
      reason: reason || null,
      created_at: new Date(),
    };
    devAuditLogs.unshift(entry);
    return entry;
  }
}

export async function fetchAuditLogs(filter: {
  admin_id?: string;
  target_table?: string;
  target_id?: string;
  from?: string;
  to?: string;
  limit?: number;
  offset?: number;
}): Promise<{ logs: AuditLogEntry[]; total: number }> {
  const { admin_id, target_table, target_id, from, to, limit = 50, offset = 0 } = filter;

  try {
    const conditions: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (admin_id) {
      conditions.push(`a.admin_id = $${idx++}`);
      values.push(admin_id);
    }
    if (target_table) {
      conditions.push(`a.target_table = $${idx++}`);
      values.push(target_table);
    }
    if (target_id) {
      conditions.push(`a.target_id = $${idx++}`);
      values.push(target_id);
    }
    if (from) {
      conditions.push(`a.created_at >= $${idx++}`);
      values.push(new Date(from));
    }
    if (to) {
      conditions.push(`a.created_at <= $${idx++}`);
      values.push(new Date(to));
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countSql = `SELECT COUNT(*)::int as total FROM admin_audit_log a ${whereClause}`;
    const countResult = await query(countSql, values);
    const total = countResult.rows[0]?.total || 0;

    const sql = `
      SELECT 
        a.*,
        u.full_name as admin_name
      FROM admin_audit_log a
      LEFT JOIN users u ON a.admin_id = u.id
      ${whereClause}
      ORDER BY a.created_at DESC
      LIMIT $${idx++} OFFSET $${idx++}
    `;

    const result = await query(sql, [...values, limit, offset]);
    return { logs: result.rows, total };
  } catch (err: any) {
    let filtered = [...devAuditLogs];

    if (admin_id) filtered = filtered.filter((l) => l.admin_id === admin_id);
    if (target_table) filtered = filtered.filter((l) => l.target_table === target_table);
    if (target_id) filtered = filtered.filter((l) => l.target_id === target_id);
    if (from) filtered = filtered.filter((l) => new Date(l.created_at) >= new Date(from));
    if (to) filtered = filtered.filter((l) => new Date(l.created_at) <= new Date(to));

    const total = filtered.length;
    const paginated = filtered.slice(offset, offset + limit);
    return { logs: paginated, total };
  }
}
