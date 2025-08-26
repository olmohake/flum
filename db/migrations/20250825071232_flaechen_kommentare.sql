-- migrate:up
create table flaechenkommentare(
    id uuid primary key default gen_random_uuid(),
    flaechen_id uuid not null references flaechen(id),
    text text not null,
    erstellt_am date not null default now()
);

-- migrate:down
drop table flaechenkommentare;
