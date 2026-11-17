-- Settings of the gateway (route_id null) and of each route: one row per feature (`key`, e.g. 'maintenance'), its
-- value a json the code validates. A new feature is a new key, no migration. See DECISIONS.md.
CREATE TABLE public.setting
(
    setting_id uuid                     NOT NULL DEFAULT gen_random_uuid(),
    route_id   uuid REFERENCES public.route (route_id) ON DELETE CASCADE,
    key        character varying(64)    NOT NULL,
    value      jsonb                    NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    PRIMARY KEY (setting_id)
);

-- One value per key: two partial indexes, a unique constraint would allow repeated keys with a null route_id
CREATE UNIQUE INDEX uq_setting_global ON public.setting (key) WHERE route_id IS NULL;
CREATE UNIQUE INDEX uq_setting_route ON public.setting (route_id, key) WHERE route_id IS NOT NULL;
