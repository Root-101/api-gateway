-- Sorted logs search and the daily clean up of old logs both filter/sort by requested_at.
-- Not CONCURRENTLY: it deadlocks with the Flyway transactional lock. It runs before the server starts; the log inserts of other replicas only wait in their queue meanwhile.
CREATE INDEX IF NOT EXISTS idx_http_log_requested_at ON public.http_log (requested_at);
