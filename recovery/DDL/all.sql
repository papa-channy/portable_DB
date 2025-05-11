--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Debian 16.9-1.pgdg120+1)
-- Dumped by pg_dump version 16.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auto_attach_change_tracker(); Type: FUNCTION; Schema: public; Owner: chan
--

CREATE FUNCTION public.auto_attach_change_tracker() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        obj RECORD;
    BEGIN
        FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
        LOOP
            IF obj.object_type = 'table' AND obj.schema_name = 'public' THEN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_trigger
                    WHERE tgrelid = obj.object_identity::regclass
                    AND tgname = 'change_tracker_trigger_' || obj.object_name
                ) THEN
                    EXECUTE format('
                        CREATE TRIGGER change_tracker_trigger_%1$s
                        BEFORE UPDATE OR DELETE ON public.%1$I
                        FOR EACH ROW EXECUTE FUNCTION track_changes()',
                        obj.object_name
                    );
                END IF;
            END IF;
        END LOOP;
    END;
    $_$;


ALTER FUNCTION public.auto_attach_change_tracker() OWNER TO chan;

--
-- Name: track_changes(); Type: FUNCTION; Schema: public; Owner: chan
--

CREATE FUNCTION public.track_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      NEW.updated_at := NOW();
      RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.track_changes() OWNER TO chan;

--
-- Name: trg_on_create_table; Type: EVENT TRIGGER; Schema: -; Owner: chan
--

CREATE EVENT TRIGGER trg_on_create_table ON ddl_command_end
         WHEN TAG IN ('CREATE TABLE')
   EXECUTE FUNCTION public.auto_attach_change_tracker();


ALTER EVENT TRIGGER trg_on_create_table OWNER TO chan;

--
-- PostgreSQL database dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 16.9 (Debian 16.9-1.pgdg120+1)
-- Dumped by pg_dump version 16.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auto_attach_change_tracker(); Type: FUNCTION; Schema: public; Owner: chan
--

CREATE FUNCTION public.auto_attach_change_tracker() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
        obj RECORD;
    BEGIN
        FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands()
        LOOP
            IF obj.object_type = 'table' AND obj.schema_name = 'public' THEN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_trigger
                    WHERE tgrelid = obj.object_identity::regclass
                    AND tgname = 'change_tracker_trigger_' || obj.object_name
                ) THEN
                    EXECUTE format('
                        CREATE TRIGGER change_tracker_trigger_%1$s
                        BEFORE UPDATE OR DELETE ON public.%1$I
                        FOR EACH ROW EXECUTE FUNCTION track_changes()',
                        obj.object_name
                    );
                END IF;
            END IF;
        END LOOP;
    END;
    $_$;


ALTER FUNCTION public.auto_attach_change_tracker() OWNER TO chan;

--
-- Name: track_changes(); Type: FUNCTION; Schema: public; Owner: chan
--

CREATE FUNCTION public.track_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      NEW.updated_at := NOW();
      RETURN NEW;
    END;
    $$;


ALTER FUNCTION public.track_changes() OWNER TO chan;

--
-- Name: trg_on_create_table; Type: EVENT TRIGGER; Schema: -; Owner: chan
--

CREATE EVENT TRIGGER trg_on_create_table ON ddl_command_end
         WHEN TAG IN ('CREATE TABLE')
   EXECUTE FUNCTION public.auto_attach_change_tracker();


ALTER EVENT TRIGGER trg_on_create_table OWNER TO chan;

--
-- PostgreSQL database dump complete
--

