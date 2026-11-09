ALTER TABLE public.route
    ADD COLUMN route_order integer NOT NULL DEFAULT 0,
    ADD COLUMN rules       text    NOT NULL DEFAULT '{}';
