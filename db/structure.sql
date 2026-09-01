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

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: admin_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_sessions (
    id bigint NOT NULL,
    admin_user_id bigint NOT NULL,
    ip_address character varying,
    user_agent character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: admin_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_sessions_id_seq OWNED BY public.admin_sessions.id;


--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_users_id_seq OWNED BY public.admin_users.id;


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
-- Name: chat_conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_conversations (
    id bigint NOT NULL,
    journey_session_id uuid NOT NULL,
    stage integer DEFAULT 0 NOT NULL,
    context_tag character varying,
    municipality_id bigint,
    service_category_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: chat_conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_conversations_id_seq OWNED BY public.chat_conversations.id;


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_messages (
    id bigint NOT NULL,
    chat_conversation_id bigint NOT NULL,
    role integer NOT NULL,
    card_type integer,
    body text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_messages_id_seq OWNED BY public.chat_messages.id;


--
-- Name: content_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_pages (
    id bigint NOT NULL,
    content_type integer NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    summary text,
    body text,
    taxonomy_tag_id bigint,
    show_find_service_cta boolean DEFAULT true NOT NULL,
    show_chat_cta boolean DEFAULT true NOT NULL,
    published_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: content_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_pages_id_seq OWNED BY public.content_pages.id;


--
-- Name: partners_partners; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partners_partners (
    id bigint NOT NULL,
    name character varying NOT NULL,
    partner_type character varying NOT NULL,
    description text,
    url character varying,
    coverage_scope character varying,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: partners_partners_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.partners_partners_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partners_partners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.partners_partners_id_seq OWNED BY public.partners_partners.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: taxonomy_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taxonomy_tags (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    label character varying NOT NULL,
    kind integer DEFAULT 0 NOT NULL,
    parent_id bigint,
    active boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: taxonomy_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taxonomy_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taxonomy_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taxonomy_tags_id_seq OWNED BY public.taxonomy_tags.id;


--
-- Name: territorial_facilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.territorial_facilities (
    id bigint NOT NULL,
    name character varying NOT NULL,
    facility_type character varying NOT NULL,
    address character varying,
    neighborhood character varying,
    cep character varying,
    municipality_id bigint NOT NULL,
    latitude double precision,
    longitude double precision,
    phone character varying,
    opening_hours character varying,
    description text,
    access_info text,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    location public.geography(Point,4326)
);


--
-- Name: territorial_facilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.territorial_facilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: territorial_facilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.territorial_facilities_id_seq OWNED BY public.territorial_facilities.id;


--
-- Name: territorial_facility_service_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.territorial_facility_service_categories (
    id bigint NOT NULL,
    facility_id bigint NOT NULL,
    service_category_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: territorial_facility_service_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.territorial_facility_service_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: territorial_facility_service_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.territorial_facility_service_categories_id_seq OWNED BY public.territorial_facility_service_categories.id;


--
-- Name: territorial_municipalities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.territorial_municipalities (
    id bigint NOT NULL,
    ibge_code character varying NOT NULL,
    name character varying NOT NULL,
    region character varying,
    state character varying DEFAULT 'MG'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: territorial_municipalities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.territorial_municipalities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: territorial_municipalities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.territorial_municipalities_id_seq OWNED BY public.territorial_municipalities.id;


--
-- Name: territorial_service_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.territorial_service_categories (
    id bigint NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    taxonomy_tag_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: territorial_service_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.territorial_service_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: territorial_service_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.territorial_service_categories_id_seq OWNED BY public.territorial_service_categories.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: admin_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions ALTER COLUMN id SET DEFAULT nextval('public.admin_sessions_id_seq'::regclass);


--
-- Name: admin_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users ALTER COLUMN id SET DEFAULT nextval('public.admin_users_id_seq'::regclass);


--
-- Name: chat_conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_conversations ALTER COLUMN id SET DEFAULT nextval('public.chat_conversations_id_seq'::regclass);


--
-- Name: chat_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN id SET DEFAULT nextval('public.chat_messages_id_seq'::regclass);


--
-- Name: content_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_pages ALTER COLUMN id SET DEFAULT nextval('public.content_pages_id_seq'::regclass);


--
-- Name: partners_partners id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partners_partners ALTER COLUMN id SET DEFAULT nextval('public.partners_partners_id_seq'::regclass);


--
-- Name: taxonomy_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxonomy_tags ALTER COLUMN id SET DEFAULT nextval('public.taxonomy_tags_id_seq'::regclass);


--
-- Name: territorial_facilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_facilities ALTER COLUMN id SET DEFAULT nextval('public.territorial_facilities_id_seq'::regclass);


--
-- Name: territorial_facility_service_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_facility_service_categories ALTER COLUMN id SET DEFAULT nextval('public.territorial_facility_service_categories_id_seq'::regclass);


--
-- Name: territorial_municipalities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_municipalities ALTER COLUMN id SET DEFAULT nextval('public.territorial_municipalities_id_seq'::regclass);


--
-- Name: territorial_service_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_service_categories ALTER COLUMN id SET DEFAULT nextval('public.territorial_service_categories_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: admin_sessions admin_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_pkey PRIMARY KEY (id);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: chat_conversations chat_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: content_pages content_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_pages
    ADD CONSTRAINT content_pages_pkey PRIMARY KEY (id);


--
-- Name: partners_partners partners_partners_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partners_partners
    ADD CONSTRAINT partners_partners_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: taxonomy_tags taxonomy_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxonomy_tags
    ADD CONSTRAINT taxonomy_tags_pkey PRIMARY KEY (id);


--
-- Name: territorial_facilities territorial_facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_facilities
    ADD CONSTRAINT territorial_facilities_pkey PRIMARY KEY (id);


--
-- Name: territorial_facility_service_categories territorial_facility_service_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_facility_service_categories
    ADD CONSTRAINT territorial_facility_service_categories_pkey PRIMARY KEY (id);


--
-- Name: territorial_municipalities territorial_municipalities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_municipalities
    ADD CONSTRAINT territorial_municipalities_pkey PRIMARY KEY (id);


--
-- Name: territorial_service_categories territorial_service_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_service_categories
    ADD CONSTRAINT territorial_service_categories_pkey PRIMARY KEY (id);


--
-- Name: idx_on_service_category_id_94c43e951f; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_service_category_id_94c43e951f ON public.territorial_facility_service_categories USING btree (service_category_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_admin_sessions_on_admin_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_sessions_on_admin_user_id ON public.admin_sessions USING btree (admin_user_id);


--
-- Name: index_admin_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_users_on_email_address ON public.admin_users USING btree (email_address);


--
-- Name: index_chat_conversations_on_journey_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_conversations_on_journey_session_id ON public.chat_conversations USING btree (journey_session_id);


--
-- Name: index_chat_conversations_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_conversations_on_municipality_id ON public.chat_conversations USING btree (municipality_id);


--
-- Name: index_chat_conversations_on_service_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_conversations_on_service_category_id ON public.chat_conversations USING btree (service_category_id);


--
-- Name: index_chat_messages_on_chat_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_messages_on_chat_conversation_id ON public.chat_messages USING btree (chat_conversation_id);


--
-- Name: index_content_pages_on_content_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_pages_on_content_type ON public.content_pages USING btree (content_type);


--
-- Name: index_content_pages_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_pages_on_slug ON public.content_pages USING btree (slug);


--
-- Name: index_content_pages_on_taxonomy_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_pages_on_taxonomy_tag_id ON public.content_pages USING btree (taxonomy_tag_id);


--
-- Name: index_facility_service_categories_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_facility_service_categories_uniqueness ON public.territorial_facility_service_categories USING btree (facility_id, service_category_id);


--
-- Name: index_partners_partners_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_partners_partners_on_active ON public.partners_partners USING btree (active);


--
-- Name: index_partners_partners_on_partner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_partners_partners_on_partner_type ON public.partners_partners USING btree (partner_type);


--
-- Name: index_taxonomy_tags_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taxonomy_tags_on_parent_id ON public.taxonomy_tags USING btree (parent_id);


--
-- Name: index_taxonomy_tags_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_taxonomy_tags_on_slug ON public.taxonomy_tags USING btree (slug);


--
-- Name: index_territorial_facilities_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_territorial_facilities_on_location ON public.territorial_facilities USING gist (location);


--
-- Name: index_territorial_facilities_on_municipality_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_territorial_facilities_on_municipality_id ON public.territorial_facilities USING btree (municipality_id);


--
-- Name: index_territorial_facility_service_categories_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_territorial_facility_service_categories_on_facility_id ON public.territorial_facility_service_categories USING btree (facility_id);


--
-- Name: index_territorial_municipalities_on_ibge_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_territorial_municipalities_on_ibge_code ON public.territorial_municipalities USING btree (ibge_code);


--
-- Name: index_territorial_municipalities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_territorial_municipalities_on_name ON public.territorial_municipalities USING btree (name);


--
-- Name: index_territorial_service_categories_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_territorial_service_categories_on_slug ON public.territorial_service_categories USING btree (slug);


--
-- Name: index_territorial_service_categories_on_taxonomy_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_territorial_service_categories_on_taxonomy_tag_id ON public.territorial_service_categories USING btree (taxonomy_tag_id);


--
-- Name: content_pages fk_rails_0a3b9aea23; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_pages
    ADD CONSTRAINT fk_rails_0a3b9aea23 FOREIGN KEY (taxonomy_tag_id) REFERENCES public.taxonomy_tags(id);


--
-- Name: chat_messages fk_rails_32ca7a4872; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT fk_rails_32ca7a4872 FOREIGN KEY (chat_conversation_id) REFERENCES public.chat_conversations(id);


--
-- Name: chat_conversations fk_rails_47522ee293; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT fk_rails_47522ee293 FOREIGN KEY (service_category_id) REFERENCES public.territorial_service_categories(id);


--
-- Name: territorial_facility_service_categories fk_rails_6c9d5d86d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_facility_service_categories
    ADD CONSTRAINT fk_rails_6c9d5d86d0 FOREIGN KEY (facility_id) REFERENCES public.territorial_facilities(id);


--
-- Name: taxonomy_tags fk_rails_7b258d327f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taxonomy_tags
    ADD CONSTRAINT fk_rails_7b258d327f FOREIGN KEY (parent_id) REFERENCES public.taxonomy_tags(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: territorial_facility_service_categories fk_rails_b652f59f35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_facility_service_categories
    ADD CONSTRAINT fk_rails_b652f59f35 FOREIGN KEY (service_category_id) REFERENCES public.territorial_service_categories(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: admin_sessions fk_rails_e5862922c9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT fk_rails_e5862922c9 FOREIGN KEY (admin_user_id) REFERENCES public.admin_users(id);


--
-- Name: territorial_service_categories fk_rails_f6f9c09d73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_service_categories
    ADD CONSTRAINT fk_rails_f6f9c09d73 FOREIGN KEY (taxonomy_tag_id) REFERENCES public.taxonomy_tags(id);


--
-- Name: territorial_facilities fk_rails_fada598365; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.territorial_facilities
    ADD CONSTRAINT fk_rails_fada598365 FOREIGN KEY (municipality_id) REFERENCES public.territorial_municipalities(id);


--
-- Name: chat_conversations fk_rails_fe0823b734; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT fk_rails_fe0823b734 FOREIGN KEY (municipality_id) REFERENCES public.territorial_municipalities(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260813182834'),
('20260813182833'),
('20260813181646'),
('20260813181641'),
('20260813163643'),
('20260813143658'),
('20260813143657'),
('20260813143656'),
('20260813143655'),
('20260813143654'),
('20260813143653'),
('20260813143652');

