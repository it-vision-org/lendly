alter table users add column email_verified_at timestamptz;

-- Grandfather every existing account as verified so nobody already using the
-- app is locked out by this migration. New signups start unverified.
update users set email_verified_at = created_at;

create table email_verifications (
    id uuid primary key,
    user_id uuid not null references users (id) on delete cascade,
    code_hash varchar(255) not null,
    expires_at timestamptz not null,
    attempts int not null default 0,
    verified_at timestamptz,
    ip_address varchar(64),
    created_at timestamptz not null default now()
);

create index idx_email_verifications_user_id on email_verifications (user_id);
create index idx_email_verifications_created_at on email_verifications (created_at);
create index idx_email_verifications_ip_address on email_verifications (ip_address);
