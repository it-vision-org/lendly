create table users (
    id uuid primary key,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    email varchar(255) not null unique,
    password_hash varchar(255) not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table refresh_tokens (
    id uuid primary key,
    user_id uuid not null references users (id) on delete cascade,
    token_hash varchar(255) not null unique,
    device_info varchar(255),
    issued_at timestamptz not null,
    expires_at timestamptz not null,
    revoked_at timestamptz
);

create index idx_refresh_tokens_user_id on refresh_tokens (user_id);

create table contacts (
    id uuid primary key,
    user_id uuid not null references users (id) on delete cascade,
    name varchar(150) not null,
    phone varchar(30),
    email varchar(255),
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_contacts_user_id on contacts (user_id);

create table transactions (
    id uuid primary key,
    user_id uuid not null references users (id) on delete cascade,
    contact_id uuid not null references contacts (id) on delete cascade,
    type varchar(20) not null check (type in ('LENT', 'BORROWED')),
    original_amount numeric(14, 2) not null check (original_amount > 0),
    remaining_amount numeric(14, 2) not null check (remaining_amount >= 0),
    currency varchar(3) not null default 'TND',
    description varchar(500),
    transaction_date date not null,
    status varchar(20) not null check (status in ('ACTIVE', 'PARTIALLY_PAID', 'PAID')),
    version bigint not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_transactions_user_id on transactions (user_id);
create index idx_transactions_contact_id on transactions (contact_id);
create index idx_transactions_status on transactions (status);
create index idx_transactions_type on transactions (type);

create table repayments (
    id uuid primary key,
    transaction_id uuid not null references transactions (id) on delete cascade,
    amount numeric(14, 2) not null check (amount > 0),
    payment_date date not null,
    notes varchar(500),
    created_at timestamptz not null default now()
);

create index idx_repayments_transaction_id on repayments (transaction_id);
