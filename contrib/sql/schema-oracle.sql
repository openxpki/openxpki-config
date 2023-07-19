-- Schema version v3 - 2023-07-19

DROP TABLE aliases CASCADE CONSTRAINTS;

CREATE TABLE aliases (
  identifier varchar2(64),
  pki_realm varchar2(255) NOT NULL,
  alias varchar2(255) NOT NULL,
  group_id varchar2(255),
  generation number,
  notafter number,
  notbefore number,
  PRIMARY KEY (pki_realm, alias)
);

--
-- Table: application_log
--;

DROP TABLE application_log CASCADE CONSTRAINTS;

CREATE TABLE application_log (
  application_log_id number NOT NULL,
  logtimestamp number,
  workflow_id number(38,0) NOT NULL,
  priority number DEFAULT '0',
  category varchar2(255) NOT NULL,
  message clob,
  PRIMARY KEY (application_log_id)
);

--
-- Table: audittrail
--;

DROP TABLE audittrail CASCADE CONSTRAINTS;

DROP SEQUENCE sq_audittrail_audittrail_key;

CREATE SEQUENCE sq_audittrail_audittrail_key;

CREATE TABLE audittrail (
  audittrail_key number NOT NULL,
  logtimestamp number,
  category varchar2(255),
  loglevel varchar2(255),
  message clob,
  PRIMARY KEY (audittrail_key)
);

--
-- Table: certificate
--;

DROP TABLE certificate CASCADE CONSTRAINTS;

CREATE TABLE certificate (
  pki_realm varchar2(255),
  issuer_dn varchar2(1000),
  cert_key number(38,0) NOT NULL,
  issuer_identifier varchar2(64) NOT NULL,
  identifier varchar2(64),
  subject varchar2(1000),
  status varchar2(255),
  subject_key_identifier varchar2(255),
  authority_key_identifier varchar2(255),
  notbefore number,
  notafter number,
  revocation_time number,
  invalidity_time number,
  reason_code varchar2(64),
  hold_instruction_code varchar2(64),
  req_key number,
  data clob,
  PRIMARY KEY (issuer_identifier, cert_key)
);

--
-- Table: certificate_attributes
--;

DROP TABLE certificate_attributes CASCADE CONSTRAINTS;

CREATE TABLE certificate_attributes (
  identifier varchar2(64) NOT NULL,
  attribute_key number NOT NULL,
  attribute_contentkey varchar2(255),
  attribute_value varchar2(4000),
  PRIMARY KEY (attribute_key, identifier)
);

--
-- Table: crl
--;

DROP TABLE crl CASCADE CONSTRAINTS;

CREATE TABLE crl (
  pki_realm varchar2(255) NOT NULL,
  issuer_identifier varchar2(64) NOT NULL,
  profile varchar2(64),
  crl_key number(38,0) NOT NULL,
  crl_number number(38,0),
  items number,
  data clob,
  last_update number,
  next_update number,
  publication_date number,
  PRIMARY KEY (issuer_identifier, crl_key)
);

--
-- Table: csr
--;

DROP TABLE csr CASCADE CONSTRAINTS;

CREATE TABLE csr (
  req_key number NOT NULL,
  pki_realm varchar2(255) NOT NULL,
  format varchar2(25),
  profile varchar2(255),
  subject varchar2(1000),
  data clob,
  PRIMARY KEY (pki_realm, req_key)
);

--
-- Table: csr_attributes
--;

DROP TABLE csr_attributes CASCADE CONSTRAINTS;

CREATE TABLE csr_attributes (
  attribute_key number NOT NULL,
  pki_realm varchar2(255) NOT NULL,
  req_key number(38,0) NOT NULL,
  attribute_contentkey varchar2(255),
  attribute_value clob,
  attribute_source clob,
  PRIMARY KEY (attribute_key, pki_realm, req_key)
);

--
-- Table: datapool
--;

DROP TABLE datapool CASCADE CONSTRAINTS;

CREATE TABLE datapool (
  pki_realm varchar2(255) NOT NULL,
  namespace varchar2(255) NOT NULL,
  datapool_key varchar2(255) NOT NULL,
  datapool_value clob,
  encryption_key varchar2(255),
  access_key varchar2(255),
  notafter number,
  last_update number,
  PRIMARY KEY (pki_realm, namespace, datapool_key)
);

--
-- Table: report
--;

DROP TABLE report CASCADE CONSTRAINTS;

create table report (
  report_name varchar2(63),
  pki_realm varchar2(255),
  created number(38), -- unix timestamp
  mime_type varchar2(63), -- advisory, e.g. text/csv, text/plain, application/pdf, ...
  description varchar2(255),
  report_value clob,
  primary key (report_name, pki_realm)
);

--
-- Table: secret
--;

DROP TABLE secret CASCADE CONSTRAINTS;

CREATE TABLE secret (
  pki_realm varchar2(255) NOT NULL,
  group_id varchar2(255) NOT NULL,
  data clob,
  PRIMARY KEY (pki_realm, group_id)
);

--
-- Table: backend_session
--;

DROP TABLE backend_session CASCADE CONSTRAINTS;

CREATE TABLE backend_session (
  session_id varchar2(255) NOT NULL,
  data clob,
  created number NOT NULL,
  modified number NOT NULL,
  ip_address varchar2(45),
  PRIMARY KEY (session_id)
);

--
-- Table: frontend_session
--;

DROP TABLE frontend_session CASCADE CONSTRAINTS;

CREATE TABLE frontend_session (
  session_id varchar2(255) NOT NULL,
  data clob,
  created number NOT NULL,
  modified number NOT NULL,
  ip_address varchar2(45),
  PRIMARY KEY (session_id)
);

--
-- Table: workflow
--;

DROP TABLE workflow CASCADE CONSTRAINTS;

CREATE TABLE workflow (
  workflow_id number NOT NULL,
  pki_realm varchar2(255),
  workflow_type varchar2(255),
  workflow_state varchar2(255),
  workflow_last_update varchar2(20) NOT NULL,
  workflow_proc_state varchar2(32),
  workflow_wakeup_at number,
  workflow_count_try number,
  workflow_archive_at number,
  workflow_session clob,
  watchdog_key varchar2(64),
  PRIMARY KEY (workflow_id)
);

--
-- Table: workflow_attributes
--;

DROP TABLE workflow_attributes CASCADE CONSTRAINTS;

CREATE TABLE workflow_attributes (
  workflow_id number NOT NULL,
  attribute_contentkey varchar2(255) NOT NULL,
  attribute_value varchar2(4000),
  PRIMARY KEY (workflow_id, attribute_contentkey)
);

--
-- Table: workflow_context
--;

DROP TABLE workflow_context CASCADE CONSTRAINTS;

CREATE TABLE workflow_context (
  workflow_id number NOT NULL,
  workflow_context_key varchar2(255) NOT NULL,
  workflow_context_value clob,
  PRIMARY KEY (workflow_id, workflow_context_key)
);

--
-- Table: workflow_history
--;

DROP TABLE workflow_history CASCADE CONSTRAINTS;

CREATE TABLE workflow_history (
  workflow_hist_id number NOT NULL,
  workflow_id number,
  workflow_action varchar2(255),
  workflow_description clob,
  workflow_state varchar2(255),
  workflow_user varchar2(255),
  workflow_history_date varchar2(20) NOT NULL,
  workflow_node varchar2(64),
  PRIMARY KEY (workflow_hist_id)
);

DROP TABLE ocsp_responses CASCADE CONSTRAINTS;

CREATE TABLE ocsp_responses (
  identifier varchar2(64),
  serial_number varchar2(128) NOT NULL,
  authority_key_identifier varchar2(128) NOT NULL,
  body clob NOT NULL,
  expiry timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY (serial_number, authority_key_identifier)
);


CREATE OR REPLACE TRIGGER ai_audittrail_audittrail_key
BEFORE INSERT ON audittrail
FOR EACH ROW WHEN (
 new.audittrail_key IS NULL OR new.audittrail_key = 0
)
BEGIN
 SELECT sq_audittrail_audittrail_key.nextval
 INTO :new.audittrail_key
 FROM dual;
END;
/

DROP SEQUENCE seq_application_log;
CREATE SEQUENCE seq_application_log START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_audittrail;
CREATE SEQUENCE seq_audittrail START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_certificate;
CREATE SEQUENCE seq_certificate START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_certificate_attributes;
CREATE SEQUENCE seq_certificate_attributes START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_crl;
CREATE SEQUENCE seq_crl START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_csr;
CREATE SEQUENCE seq_csr START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_csr_attributes;
CREATE SEQUENCE seq_csr_attributes START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_secret;
CREATE SEQUENCE seq_secret START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_workflow;
CREATE SEQUENCE seq_workflow START WITH 0 INCREMENT BY 1 MINVALUE 0;
DROP SEQUENCE seq_workflow_history;
CREATE SEQUENCE seq_workflow_history START WITH 0 INCREMENT BY 1 MINVALUE 0;



CREATE INDEX aliases_realm_group ON aliases (pki_realm, group_id);

CREATE INDEX application_log_id ON application_log (workflow_id);
CREATE INDEX application_log_filter ON application_log (workflow_id,category,priority);

CREATE INDEX cert_csr_serial_index ON certificate (req_key);
CREATE UNIQUE INDEX cert_identifier_index ON certificate (identifier);
CREATE INDEX cert_issuer_identifier_index ON certificate (issuer_identifier);
CREATE INDEX cert_realm_req_index ON certificate (pki_realm, req_key);
CREATE INDEX cert_realm_index ON certificate (pki_realm);
CREATE INDEX cert_status_index ON certificate (status);
CREATE INDEX cert_subject_index ON certificate (subject);
CREATE INDEX cert_notbefore_index ON certificate (notbefore);
CREATE INDEX cert_notafter_index ON certificate (notafter);
CREATE INDEX cert_revocation_time_index ON certificate (revocation_time);
CREATE INDEX cert_invalidity_time_index ON certificate (invalidity_time);
CREATE INDEX cert_reason_code_index ON certificate (reason_code);
CREATE INDEX cert_hold_index ON certificate (hold_instruction_code);
CREATE UNIQUE INDEX cert_revocation_id ON certificate (revocation_id);

CREATE INDEX cert_attributes_key_index ON certificate_attributes (attribute_contentkey);
CREATE INDEX cert_attributes_value_index ON certificate_attributes (attribute_value);
CREATE INDEX cert_attributes_identifier_index ON certificate_attributes (identifier);
CREATE INDEX cert_attributes_keyid_index ON certificate_attributes (identifier,attribute_contentkey);
CREATE INDEX cert_attributes_keyvalue_index ON certificate_attributes (attribute_contentkey,attribute_value);


CREATE INDEX crl_issuer_index ON crl (issuer_identifier);
CREATE INDEX crl_profile ON crl (profile);
CREATE INDEX crl_realm_index ON crl (pki_realm);
CREATE INDEX crl_issuer_update_index ON crl (issuer_identifier, last_update);
CREATE INDEX crl_issuer_number_index ON crl (issuer_identifier, crl_number);
CREATE INDEX crl_revocation_id ON crl (max_revocation_id);

CREATE INDEX csr_subject_index ON csr (subject);
CREATE INDEX csr_realm_index ON csr (pki_realm);
CREATE INDEX csr_realm_profile_index ON csr (pki_realm, profile);

CREATE INDEX csr_attributes_req_key_index ON csr_attributes (req_key);
CREATE INDEX csr_attributes_pki_realm_req_key_index ON csr_attributes (pki_realm, req_key);

CREATE INDEX datapool_namespace_index ON datapool (pki_realm, namespace);
CREATE INDEX datapool_notafter_index ON datapool (notafter);

CREATE INDEX backend_session_modified_index ON backend_session (modified);

CREATE INDEX frontend_session_modified_index ON frontend_session (modified);

CREATE INDEX workflow_pki_realm_index ON workflow (pki_realm);
CREATE INDEX workflow_realm_type_index ON workflow (pki_realm, workflow_type);
CREATE INDEX workflow_state_index ON workflow (pki_realm, workflow_state);
CREATE INDEX workflow_proc_state_index ON workflow (pki_realm, workflow_proc_state);
CREATE INDEX workflow_wakeup_index ON workflow (workflow_proc_state, watchdog_key, workflow_wakeup_at);
CREATE INDEX workflow_reapat_index ON workflow (workflow_proc_state, watchdog_key, workflow_reap_at);
CREATE INDEX workflow_archive_index ON workflow (workflow_proc_state, watchdog_key, workflow_archive_at);

CREATE INDEX wfl_attributes_id_index ON workflow_attributes (workflow_id);
CREATE INDEX wfl_attributes_key_index ON workflow_attributes (attribute_contentkey);
CREATE INDEX wfl_attributes_value_index ON workflow_attributes (attribute_value);
CREATE INDEX wfl_attributes_keyvalue_index ON workflow_attributes (attribute_contentkey,attribute_value);

CREATE INDEX wf_hist_wfserial_index ON workflow_history (workflow_id);

CREATE INDEX ocsp_responses_index ON ocsp_responses (identifier);


INSERT INTO datapool (`pki_realm`,`namespace`,`datapool_key`,`datapool_value`)
VALUES ('','config','dbschema','3');

QUIT;
