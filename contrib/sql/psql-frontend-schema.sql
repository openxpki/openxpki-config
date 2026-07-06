-- Schema version v5 - 2026-02-18

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: frontend_session; Type: TABLE; Schema: public; Tablespace:
--

CREATE TABLE frontend_session (
    session_id text NOT NULL,
    data text,
    created bigint NOT NULL,
    modified bigint NOT NULL,
    ip_address text
);

--
-- Name: frontend_session_pkey; Type: CONSTRAINT; Schema: public; Tablespace:
--

ALTER TABLE ONLY frontend_session
    ADD CONSTRAINT frontend_session_pkey PRIMARY KEY (session_id);

CREATE INDEX frontend_session_modified_index ON frontend_session USING btree (modified);
