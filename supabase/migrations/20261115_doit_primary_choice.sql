
create table if not exists public.doit_primary (
 group_id uuid not null references public.doit_groups(id) on delete cascade,
 day date not null,
 user_id uuid not null references auth.users(id) on delete cascade,
 slot smallint not null check(slot between 1 and 3),
 chosen_at timestamptz not null default now(),
 primary key(group_id,day,user_id)
);
alter table public.doit_primary enable row level security;
create policy "doit primary own view" on public.doit_primary for select to authenticated using(user_id=(select auth.uid()));
grant select on public.doit_primary to authenticated;
create or replace function public.doit_choose_primary(p_group uuid,p_slot integer) returns integer
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); d date:=(now() at time zone 'Europe/Lisbon')::date;
begin
 if u is null or not doit_private.is_member(p_group,u) then raise exception 'Not a member'; end if;
 if p_slot not between 1 and 3 then raise exception 'Invalid slot'; end if;
 perform public.doit_prepare_daily(p_group);
 if not exists(select 1 from public.doit_daily where group_id=p_group and day=d and slot=p_slot) then raise exception 'Unavailable quest'; end if;
 if exists(select 1 from public.doit_completions where user_id=u and group_id=p_group and day=d) then raise exception 'Main quest cannot change after completion'; end if;
 insert into public.doit_primary(group_id,day,user_id,slot) values(p_group,d,u,p_slot)
 on conflict(group_id,day,user_id) do update set slot=excluded.slot,chosen_at=now();
 return p_slot;
end $$;
revoke all on function public.doit_choose_primary(uuid,integer) from public,anon;
grant execute on function public.doit_choose_primary(uuid,integer) to authenticated;
