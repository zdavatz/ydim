--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: plpgsql_call_handler(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION plpgsql_call_handler() RETURNS language_handler
    LANGUAGE c
    AS '$libdir/plpgsql', 'plpgsql_call_handler';


ALTER FUNCTION public.plpgsql_call_handler() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: collection; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE collection (
    odba_id integer NOT NULL,
    key text NOT NULL,
    value text
);


ALTER TABLE public.collection OWNER TO ydim;

--
-- Name: object; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE object (
    odba_id integer NOT NULL,
    content text,
    name text,
    prefetchable boolean,
    extent text
);


ALTER TABLE public.object OWNER TO ydim;

--
-- Name: object_connection; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE object_connection (
    origin_id integer NOT NULL,
    target_id integer NOT NULL
);


ALTER TABLE public.object_connection OWNER TO ydim;

--
-- Name: ydim_autoinvoice_unique_id; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE ydim_autoinvoice_unique_id (
    origin_id integer,
    search_term text,
    target_id integer
);


ALTER TABLE public.ydim_autoinvoice_unique_id OWNER TO ydim;

--
-- Name: ydim_debitor_email; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE ydim_debitor_email (
    origin_id integer,
    search_term text,
    target_id integer
);


ALTER TABLE public.ydim_debitor_email OWNER TO ydim;

--
-- Name: ydim_debitor_name; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE ydim_debitor_name (
    origin_id integer,
    search_term text,
    target_id integer
);


ALTER TABLE public.ydim_debitor_name OWNER TO ydim;

--
-- Name: ydim_debitor_unique_id; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE ydim_debitor_unique_id (
    origin_id integer,
    search_term text,
    target_id integer
);


ALTER TABLE public.ydim_debitor_unique_id OWNER TO ydim;

--
-- Name: ydim_invoice_status; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE ydim_invoice_status (
    origin_id integer,
    search_term text,
    target_id integer
);


ALTER TABLE public.ydim_invoice_status OWNER TO ydim;

--
-- Name: ydim_invoice_unique_id; Type: TABLE; Schema: public; Owner: ydim; Tablespace: 
--

CREATE TABLE ydim_invoice_unique_id (
    origin_id integer,
    search_term text,
    target_id integer
);


ALTER TABLE public.ydim_invoice_unique_id OWNER TO ydim;

--
-- Data for Name: collection; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY collection (odba_id, key, value) FROM stdin;
2	0408221f7964696d5f6175746f696e766f6963655f756e697175655f6964	04086f3a0f4f4442413a3a53747562083a10406f6462615f636c61737363104f4442413a3a496e6465783a0d406f6462615f69646902dc013a14406f6462615f636f6e7461696e657230
2	040822177964696d5f64656269746f725f656d61696c	04086f3a0f4f4442413a3a53747562083a0d406f6462615f6964690296023a10406f6462615f636c61737363104f4442413a3a496e6465783a14406f6462615f636f6e7461696e657230
2	040822167964696d5f64656269746f725f6e616d65	04086f3a0f4f4442413a3a53747562083a0d406f6462615f6964690297023a10406f6462615f636c61737363104f4442413a3a496e6465783a14406f6462615f636f6e7461696e657230
2	0408221b7964696d5f64656269746f725f756e697175655f6964	04086f3a0f4f4442413a3a53747562083a0d406f6462615f6964690298023a10406f6462615f636c61737363104f4442413a3a496e6465783a14406f6462615f636f6e7461696e657230
2	040822187964696d5f696e766f6963655f737461747573	04086f3a0f4f4442413a3a53747562083a0d406f6462615f6964690299023a10406f6462615f636c61737363104f4442413a3a496e6465783a14406f6462615f636f6e7461696e657230
2	0408221b7964696d5f696e766f6963655f756e697175655f6964	04086f3a0f4f4442413a3a53747562083a0d406f6462615f696469029a023a10406f6462615f636c61737363104f4442413a3a496e6465783a14406f6462615f636f6e7461696e657230
\.


--
-- Data for Name: object; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY object (odba_id, content, name, prefetchable, extent) FROM stdin;
2	0408497b00093a0d406f6462615f696469073a14406f6462615f6f6273657276657273303a0f406f6462615f6e616d65221d5f5f63616368655f7365727665725f696e64696365735f5f3a15406f6462615f70657273697374656e7454	__cache_server_indices__	f	Hash
662	04086f3a104f4442413a3a496e6465780f3a0d406f6462615f6964690296023a1040696e6465785f6e616d6522177964696d5f64656269746f725f656d61696c3a14406f6462615f6f6273657276657273303a14407265736f6c76655f6f726967696e22003a104064696374696f6e61727922003a15406f6462615f70657273697374656e74543a12407461726765745f6b6c61737363125944494d3a3a44656269746f723a114070726f635f6f726967696e303a19407265736f6c76655f7365617263685f7465726d3a0a656d61696c3a12406f726967696e5f6b6c6173734009	\N	f	ODBA::Index
663	04086f3a104f4442413a3a496e6465780f3a0d406f6462615f6964690297023a1040696e6465785f6e616d6522167964696d5f64656269746f725f6e616d653a14406f6462615f6f6273657276657273303a14407265736f6c76655f6f726967696e22003a104064696374696f6e61727922003a15406f6462615f70657273697374656e74543a12407461726765745f6b6c61737363125944494d3a3a44656269746f723a114070726f635f6f726967696e303a19407265736f6c76655f7365617263685f7465726d3a096e616d653a12406f726967696e5f6b6c6173734009	\N	f	ODBA::Index
664	04086f3a104f4442413a3a496e6465780f3a0d406f6462615f6964690298023a1040696e6465785f6e616d65221b7964696d5f64656269746f725f756e697175655f69643a14406f6462615f6f6273657276657273303a14407265736f6c76655f6f726967696e22003a104064696374696f6e61727922003a15406f6462615f70657273697374656e74543a12407461726765745f6b6c61737363125944494d3a3a44656269746f723a114070726f635f6f726967696e303a19407265736f6c76655f7365617263685f7465726d3a0e756e697175655f69643a12406f726967696e5f6b6c6173734009	\N	f	ODBA::Index
665	04086f3a104f4442413a3a496e646578123a114070726f635f746172676574303a1040696e6465785f6e616d6522187964696d5f696e766f6963655f7374617475733a0d406f6462615f6964690299023a12406f726967696e5f6b6c61737363125944494d3a3a496e766f6963653a14406f6462615f6f6273657276657273303a114070726f635f6f726967696e303a1240636c6173735f66696c7465723a11696e7374616e63655f6f663f3a15406f6462615f70657273697374656e74543a104064696374696f6e61727922003a14407265736f6c76655f6f726967696e22003a1e4070726f635f7265736f6c76655f7365617263685f7465726d303a19407265736f6c76655f7365617263685f7465726d3a0b7374617475733a12407461726765745f6b6c6173734007	\N	f	ODBA::Index
666	04086f3a104f4442413a3a496e646578123a114070726f635f746172676574303a1040696e6465785f6e616d65221b7964696d5f696e766f6963655f756e697175655f69643a0d406f6462615f696469029a023a12406f726967696e5f6b6c61737363125944494d3a3a496e766f6963653a14406f6462615f6f6273657276657273303a114070726f635f6f726967696e303a1240636c6173735f66696c7465723a11696e7374616e63655f6f663f3a15406f6462615f70657273697374656e74543a104064696374696f6e61727922003a14407265736f6c76655f6f726967696e22003a1e4070726f635f7265736f6c76655f7365617263685f7465726d303a19407265736f6c76655f7365617263685f7465726d3a0e756e697175655f69643a12407461726765745f6b6c6173734007	\N	f	ODBA::Index
476	04086f3a104f4442413a3a496e646578123a114070726f635f746172676574303a1040696e6465785f6e616d65221f7964696d5f6175746f696e766f6963655f756e697175655f69643a12406f726967696e5f6b6c61737363165944494d3a3a4175746f496e766f6963653a0d406f6462615f69646902dc013a114070726f635f6f726967696e303a14406f6462615f6f6273657276657273303a1240636c6173735f66696c7465723a11696e7374616e63655f6f663f3a15406f6462615f70657273697374656e74543a104064696374696f6e61727922003a14407265736f6c76655f6f726967696e22003a1e4070726f635f7265736f6c76655f7365617263685f7465726d303a19407265736f6c76655f7365617263685f7465726d3a0e756e697175655f69643a12407461726765745f6b6c6173734007	\N	f	ODBA::Index
\.


--
-- Data for Name: object_connection; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY object_connection (origin_id, target_id) FROM stdin;
\.


--
-- Data for Name: ydim_autoinvoice_unique_id; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY ydim_autoinvoice_unique_id (origin_id, search_term, target_id) FROM stdin;
\.


--
-- Data for Name: ydim_debitor_email; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY ydim_debitor_email (origin_id, search_term, target_id) FROM stdin;
\.


--
-- Data for Name: ydim_debitor_name; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY ydim_debitor_name (origin_id, search_term, target_id) FROM stdin;
\.


--
-- Data for Name: ydim_debitor_unique_id; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY ydim_debitor_unique_id (origin_id, search_term, target_id) FROM stdin;
\.


--
-- Data for Name: ydim_invoice_status; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY ydim_invoice_status (origin_id, search_term, target_id) FROM stdin;
\.


--
-- Data for Name: ydim_invoice_unique_id; Type: TABLE DATA; Schema: public; Owner: ydim
--

COPY ydim_invoice_unique_id (origin_id, search_term, target_id) FROM stdin;
\.


--
-- Name: collection_pkey; Type: CONSTRAINT; Schema: public; Owner: ydim; Tablespace: 
--

ALTER TABLE ONLY collection
    ADD CONSTRAINT collection_pkey PRIMARY KEY (odba_id, key);


--
-- Name: object_connection_pkey; Type: CONSTRAINT; Schema: public; Owner: ydim; Tablespace: 
--

ALTER TABLE ONLY object_connection
    ADD CONSTRAINT object_connection_pkey PRIMARY KEY (origin_id, target_id);


--
-- Name: object_name_key; Type: CONSTRAINT; Schema: public; Owner: ydim; Tablespace: 
--

ALTER TABLE ONLY object
    ADD CONSTRAINT object_name_key UNIQUE (name);


--
-- Name: object_pkey; Type: CONSTRAINT; Schema: public; Owner: ydim; Tablespace: 
--

ALTER TABLE ONLY object
    ADD CONSTRAINT object_pkey PRIMARY KEY (odba_id);


--
-- Name: extent_index; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX extent_index ON object USING btree (extent);


--
-- Name: origin_id_index; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX origin_id_index ON object_connection USING btree (origin_id);


--
-- Name: origin_id_ydim_autoinvoice_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX origin_id_ydim_autoinvoice_unique_id ON ydim_autoinvoice_unique_id USING btree (origin_id);


--
-- Name: origin_id_ydim_debitor_email; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX origin_id_ydim_debitor_email ON ydim_debitor_email USING btree (origin_id);


--
-- Name: origin_id_ydim_debitor_name; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX origin_id_ydim_debitor_name ON ydim_debitor_name USING btree (origin_id);


--
-- Name: origin_id_ydim_debitor_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX origin_id_ydim_debitor_unique_id ON ydim_debitor_unique_id USING btree (origin_id);


--
-- Name: origin_id_ydim_invoice_status; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX origin_id_ydim_invoice_status ON ydim_invoice_status USING btree (origin_id);


--
-- Name: origin_id_ydim_invoice_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX origin_id_ydim_invoice_unique_id ON ydim_invoice_unique_id USING btree (origin_id);


--
-- Name: prefetchable_index; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX prefetchable_index ON object USING btree (prefetchable);


--
-- Name: search_term_ydim_autoinvoice_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX search_term_ydim_autoinvoice_unique_id ON ydim_autoinvoice_unique_id USING btree (search_term);


--
-- Name: search_term_ydim_debitor_email; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX search_term_ydim_debitor_email ON ydim_debitor_email USING btree (search_term);


--
-- Name: search_term_ydim_debitor_name; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX search_term_ydim_debitor_name ON ydim_debitor_name USING btree (search_term);


--
-- Name: search_term_ydim_debitor_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX search_term_ydim_debitor_unique_id ON ydim_debitor_unique_id USING btree (search_term);


--
-- Name: search_term_ydim_invoice_status; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX search_term_ydim_invoice_status ON ydim_invoice_status USING btree (search_term);


--
-- Name: search_term_ydim_invoice_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX search_term_ydim_invoice_unique_id ON ydim_invoice_unique_id USING btree (search_term);


--
-- Name: target_id_index; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX target_id_index ON object_connection USING btree (target_id);


--
-- Name: target_id_ydim_autoinvoice_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX target_id_ydim_autoinvoice_unique_id ON ydim_autoinvoice_unique_id USING btree (target_id);


--
-- Name: target_id_ydim_debitor_email; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX target_id_ydim_debitor_email ON ydim_debitor_email USING btree (target_id);


--
-- Name: target_id_ydim_debitor_name; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX target_id_ydim_debitor_name ON ydim_debitor_name USING btree (target_id);


--
-- Name: target_id_ydim_debitor_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX target_id_ydim_debitor_unique_id ON ydim_debitor_unique_id USING btree (target_id);


--
-- Name: target_id_ydim_invoice_status; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX target_id_ydim_invoice_status ON ydim_invoice_status USING btree (target_id);


--
-- Name: target_id_ydim_invoice_unique_id; Type: INDEX; Schema: public; Owner: ydim; Tablespace: 
--

CREATE INDEX target_id_ydim_invoice_unique_id ON ydim_invoice_unique_id USING btree (target_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

