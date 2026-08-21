alter table email_verifications add column purpose varchar(30) not null default 'EMAIL_VERIFICATION';
alter table email_verifications add column reset_token_hash varchar(255);
alter table email_verifications add column reset_token_expires_at timestamptz;
alter table email_verifications add column reset_token_consumed_at timestamptz;
alter table email_verifications add column version bigint not null default 0;

create index idx_email_verifications_purpose on email_verifications (purpose);
create unique index idx_email_verifications_reset_token_hash on email_verifications (reset_token_hash) where reset_token_hash is not null;
