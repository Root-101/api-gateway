-- Exact, indexed filter by route. Generated from the json in `route` (key `routeId`, see RouteLogJson): this same statement fills the old rows and the writer doesn't change.
ALTER TABLE public.http_log
    ADD COLUMN route_id uuid GENERATED ALWAYS AS ((NULLIF(route, '')::jsonb ->> 'routeId')::uuid) STORED;

CREATE INDEX idx_http_log_route_id ON public.http_log (route_id, requested_at);
