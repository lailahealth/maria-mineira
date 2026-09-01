SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: journey_chat_turns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_chat_turns (
    id bigint NOT NULL,
    journey_session_id uuid NOT NULL,
    tag_chat character varying,
    subtag_chat character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: journey_chat_turns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.journey_chat_turns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journey_chat_turns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.journey_chat_turns_id_seq OWNED BY public.journey_chat_turns.id;


--
-- Name: journey_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_events (
    id bigint NOT NULL,
    journey_session_id uuid NOT NULL,
    event_type integer NOT NULL,
    tag character varying,
    subtag character varying,
    municipality_ibge_code character varying,
    categoria_servico character varying,
    equipamento_indicado_id bigint,
    equipamento_indicado_nome character varying,
    resultado integer,
    distancia_aproximada_km double precision,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: journey_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.journey_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journey_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.journey_events_id_seq OWNED BY public.journey_events.id;


--
-- Name: journey_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journey_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    started_at timestamp(6) without time zone NOT NULL,
    tag_origem character varying,
    subtag_origem character varying,
    plataforma_origem character varying,
    campanha character varying,
    conteudo_origem character varying,
    pagina_entrada character varying,
    municipality_ibge_code character varying,
    device_hint character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: journey_chat_turns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_chat_turns ALTER COLUMN id SET DEFAULT nextval('public.journey_chat_turns_id_seq'::regclass);


--
-- Name: journey_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_events ALTER COLUMN id SET DEFAULT nextval('public.journey_events_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: journey_chat_turns journey_chat_turns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_chat_turns
    ADD CONSTRAINT journey_chat_turns_pkey PRIMARY KEY (id);


--
-- Name: journey_events journey_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_events
    ADD CONSTRAINT journey_events_pkey PRIMARY KEY (id);


--
-- Name: journey_sessions journey_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_sessions
    ADD CONSTRAINT journey_sessions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_journey_chat_turns_on_journey_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journey_chat_turns_on_journey_session_id ON public.journey_chat_turns USING btree (journey_session_id);


--
-- Name: index_journey_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journey_events_on_event_type ON public.journey_events USING btree (event_type);


--
-- Name: index_journey_events_on_journey_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journey_events_on_journey_session_id ON public.journey_events USING btree (journey_session_id);


--
-- Name: index_journey_events_on_municipality_ibge_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journey_events_on_municipality_ibge_code ON public.journey_events USING btree (municipality_ibge_code);


--
-- Name: index_journey_events_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journey_events_on_tag ON public.journey_events USING btree (tag);


--
-- Name: journey_events fk_rails_007e891d5e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_events
    ADD CONSTRAINT fk_rails_007e891d5e FOREIGN KEY (journey_session_id) REFERENCES public.journey_sessions(id);


--
-- Name: journey_chat_turns fk_rails_9fa3a5b5f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journey_chat_turns
    ADD CONSTRAINT fk_rails_9fa3a5b5f1 FOREIGN KEY (journey_session_id) REFERENCES public.journey_sessions(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260813143657'),
('20260813143656'),
('20260813143655');

