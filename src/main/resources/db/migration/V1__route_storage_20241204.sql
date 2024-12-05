CREATE TABLE public.route
(
    route_id serial NOT NULL,
    name character varying(256) NOT NULL,
    path character varying(256) NOT NULL,
    uri character varying(256) NOT NULL,
    rewrite_path_from character varying(256),
    rewrite_path_to character varying(256),
    description text,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT route_primary_key PRIMARY KEY (route_id),
    CONSTRAINT unique_route_name UNIQUE (name)
);