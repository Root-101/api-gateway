-- The add-ons of the gateway (route_id null) and of each route: one row per type ('maintenance'; later 'rate_limit',
-- 'health_check'...). A new type is a new value of `type`, no migration: the code owns the valid types and the shape
-- of each json. See DECISIONS.md.
CREATE TABLE public.addon
(
    addon_id   uuid                     NOT NULL DEFAULT gen_random_uuid(),
    -- null = the whole gateway
    route_id   uuid REFERENCES public.route (route_id) ON DELETE CASCADE,
    type       character varying(64)    NOT NULL,
    -- what the admin sets
    config     jsonb                    NOT NULL CHECK (jsonb_typeof(config) = 'object'),
    -- what the gateway itself writes (e.g. when it was last turned on), null when there is nothing
    state      jsonb CHECK (state IS NULL OR jsonb_typeof(state) = 'object'),
    created_at timestamp with time zone NOT NULL,
    -- the last change of `config`
    updated_at timestamp with time zone NOT NULL,
    PRIMARY KEY (addon_id)
);

-- One per type: two partial indexes, a unique constraint would allow repeated types with a null route_id
CREATE UNIQUE INDEX uq_addon_gateway ON public.addon (type) WHERE route_id IS NULL;
CREATE UNIQUE INDEX uq_addon_route ON public.addon (route_id, type) WHERE route_id IS NOT NULL;
