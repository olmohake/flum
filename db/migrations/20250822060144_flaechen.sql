-- migrate:up
create extension postgis;
create table flaechen(
    id uuid primary key default gen_random_uuid(),
    art text not null default 'Denkfläche',
    geometry geometry(Polygon, 25833),
    angelegt_am date not null default now()
);



-- migrate:down
drop table flaechen;
