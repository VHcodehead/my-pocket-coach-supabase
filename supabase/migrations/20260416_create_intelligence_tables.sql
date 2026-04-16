-- Intelligence Snapshots: weekly composite score + per-node data for historical growth tracking
CREATE TABLE IF NOT EXISTS intelligence_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  snapshot_date DATE NOT NULL,
  composite_score NUMERIC(5,2) DEFAULT 0,
  category_scores JSONB DEFAULT '{}',
  node_data JSONB DEFAULT '[]',
  active_node_count INTEGER DEFAULT 0,
  total_data_points INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, snapshot_date)
);

CREATE INDEX IF NOT EXISTS idx_intelligence_snapshots_user
  ON intelligence_snapshots (user_id, snapshot_date DESC);

-- Intelligence Node Activations: tracks when each node first crosses activation threshold
CREATE TABLE IF NOT EXISTS intelligence_node_activations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  node_id TEXT NOT NULL,
  first_activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, node_id)
);

CREATE INDEX IF NOT EXISTS idx_intelligence_node_activations_user
  ON intelligence_node_activations (user_id);

-- RLS: Backend uses service role key (bypasses RLS), but enable for safety
ALTER TABLE intelligence_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE intelligence_node_activations ENABLE ROW LEVEL SECURITY;
