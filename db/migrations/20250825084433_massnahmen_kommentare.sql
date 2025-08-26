-- migrate:up
create table massnahmenkommentare(
    id uuid primary key default gen_random_uuid(),
    massnahmen_id uuid not null references massnahmen(id),
    text text not null,
    erstellt_am date not null default now()
);

-- migrate:down
drop table massnahmenkommentare;
