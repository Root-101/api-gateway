CREATE TABLE public.http_log
(
    http_log_id      uuid                     NOT NULL DEFAULT gen_random_uuid(),
    source_ip        character varying(50),
    requested_at     timestamp with time zone NOT NULL,
    user_agent       text,
    http_method      character varying(25)    NOT NULL,
    path             text                     NOT NULL,
    response_code    integer                  NOT NULL,
    request_duration integer                  NOT NULL,
    route            text,
    PRIMARY KEY (http_log_id)
);