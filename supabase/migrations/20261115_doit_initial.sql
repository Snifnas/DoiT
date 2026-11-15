
create schema if not exists doit_private;
create table if not exists public.doit_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Adventurer',
 blocked_tags text[] not null default '{}',
 xp integer not null default 0 check(xp>=0),
 coins integer not null default 0 check(coins>=0),
 rerolls integer not null default 1 check(rerolls between 0 and 3),
 freezes integer not null default 1 check(freezes between 0 and 2),
 streak integer not null default 0,
 last_day date,
 equipped_frame text,
 equipped_theme text,
 created_at timestamptz not null default now()
);
create table if not exists public.doit_groups (
 id uuid primary key default gen_random_uuid(),
 name text not null check(char_length(name) between 2 and 64),
 owner_id uuid not null references auth.users(id),
 invite_code text not null unique default upper(substr(replace(gen_random_uuid()::text,'-',''),1,10)),
 blocked_tags text[] not null default '{}',
 created_at timestamptz not null default now()
);
create table if not exists public.doit_members (
 group_id uuid not null references public.doit_groups(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'member' check(role in ('owner','member')),
 joined_at timestamptz not null default now(),
 primary key(group_id,user_id)
);
create table if not exists public.doit_skills (
 key text primary key, category text not null, name text not null, icon text not null default 'sparkles'
);
create table if not exists public.doit_quests (
 id uuid primary key default gen_random_uuid(),
 title text not null check(char_length(title) between 5 and 140),
 description text not null check(char_length(description) between 10 and 1200),
 skill_key text not null references public.doit_skills(key),
 difficulty text not null check(difficulty in ('easy','medium','hard')),
 minutes integer not null check(minutes between 5 and 300),
 xp integer not null check(xp between 10 and 750),
 tags text[] not null default '{}',
 group_id uuid references public.doit_groups(id) on delete cascade,
 created_by uuid references auth.users(id),
 active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.doit_daily (
 group_id uuid not null references public.doit_groups(id) on delete cascade,
 day date not null,
 slot smallint not null check(slot between 1 and 3),
 quest_id uuid not null references public.doit_quests(id),
 primary key(group_id,day,slot)
);
create table if not exists public.doit_swaps (
 group_id uuid not null references public.doit_groups(id) on delete cascade,
 day date not null,
 slot smallint not null check(slot between 1 and 3),
 user_id uuid not null references auth.users(id) on delete cascade,
 quest_id uuid not null references public.doit_quests(id),
 kind text not null check(kind in ('accessibility','reroll')),
 primary key(group_id,day,slot,user_id)
);
create table if not exists public.doit_completions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 group_id uuid not null references public.doit_groups(id) on delete cascade,
 day date not null,
 slot smallint not null check(slot between 1 and 3),
 quest_id uuid not null references public.doit_quests(id),
 photo_path text not null unique,
 xp_awarded integer not null default 0,
 created_at timestamptz not null default now(),
 unique(user_id,group_id,day,slot)
);
create table if not exists public.doit_xp_ledger (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 day date not null,
 quest_id uuid references public.doit_quests(id),
 source text not null check(source in ('quest','daily_bonus')),
 xp integer not null check(xp>=0),
 skill_key text references public.doit_skills(key),
 created_at timestamptz default now()
);
create unique index if not exists doit_xp_quest_daily on public.doit_xp_ledger(user_id,day,quest_id) where source='quest';
create unique index if not exists doit_xp_bonus_daily on public.doit_xp_ledger(user_id,day) where source='daily_bonus';
create table if not exists public.doit_achievements (
 user_id uuid not null references auth.users(id) on delete cascade,
 code text not null,
 earned_at timestamptz not null default now(),
 primary key(user_id,code)
);
create table if not exists public.doit_shop (
 id text primary key, title text not null, kind text not null check(kind in ('frame','theme')), price integer not null, icon text not null
);
create table if not exists public.doit_owned (
 user_id uuid not null references auth.users(id) on delete cascade,
 item_id text not null references public.doit_shop(id),
 acquired_at timestamptz not null default now(),
 primary key(user_id,item_id)
);
create table if not exists public.doit_comments (
 id uuid primary key default gen_random_uuid(),
 completion_id uuid not null references public.doit_completions(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(char_length(body) between 1 and 400),
 created_at timestamptz not null default now()
);
create table if not exists public.doit_reactions (
 completion_id uuid not null references public.doit_completions(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 emoji text not null check(emoji in ('🔥','👏','❤️','😂','🤯')),
 primary key(completion_id,user_id)
);
create table if not exists public.doit_alerts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 text text not null,
 read_at timestamptz,
 created_at timestamptz not null default now()
);
create index if not exists doit_completions_feed on public.doit_completions(group_id,created_at desc);
create index if not exists doit_members_user on public.doit_members(user_id);
create index if not exists doit_quests_filter on public.doit_quests(group_id,difficulty,active);
create or replace function doit_private.is_member(g uuid,u uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.doit_members m where m.group_id=g and m.user_id=u);
$$;
create or replace function doit_private.are_peers(a uuid,b uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.doit_members x join public.doit_members y on x.group_id=y.group_id where x.user_id=a and y.user_id=b);
$$;
create or replace function doit_private.is_owner(g uuid,u uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.doit_groups where id=g and owner_id=u);
$$;
revoke all on function doit_private.is_member(uuid,uuid),doit_private.are_peers(uuid,uuid),doit_private.is_owner(uuid,uuid) from public;
grant usage on schema doit_private to authenticated;
grant execute on function doit_private.is_member(uuid,uuid),doit_private.are_peers(uuid,uuid),doit_private.is_owner(uuid,uuid) to authenticated;
alter table public.doit_profiles enable row level security;
alter table public.doit_groups enable row level security;
alter table public.doit_members enable row level security;
alter table public.doit_skills enable row level security;
alter table public.doit_quests enable row level security;
alter table public.doit_daily enable row level security;
alter table public.doit_swaps enable row level security;
alter table public.doit_completions enable row level security;
alter table public.doit_xp_ledger enable row level security;
alter table public.doit_achievements enable row level security;
alter table public.doit_shop enable row level security;
alter table public.doit_owned enable row level security;
alter table public.doit_comments enable row level security;
alter table public.doit_reactions enable row level security;
alter table public.doit_alerts enable row level security;
create policy "doit profile group visibility" on public.doit_profiles for select to authenticated using (id=(select auth.uid()) or doit_private.are_peers(id,(select auth.uid())));
create policy "doit own profile edits" on public.doit_profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy "doit groups members view" on public.doit_groups for select to authenticated using(doit_private.is_member(id,(select auth.uid())));
create policy "doit groups owner edits" on public.doit_groups for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy "doit members group view" on public.doit_members for select to authenticated using(doit_private.is_member(group_id,(select auth.uid())));
create policy "doit skills view" on public.doit_skills for select to authenticated using(true);
create policy "doit quest view" on public.doit_quests for select to authenticated using(active and (group_id is null or doit_private.is_member(group_id,(select auth.uid()))) or (group_id is not null and doit_private.is_owner(group_id,(select auth.uid()))));
create policy "doit owner custom quest create" on public.doit_quests for insert to authenticated with check(group_id is not null and doit_private.is_owner(group_id,(select auth.uid())) and created_by=(select auth.uid()));
create policy "doit owner custom quest edit" on public.doit_quests for update to authenticated using(group_id is not null and doit_private.is_owner(group_id,(select auth.uid()))) with check(group_id is not null and doit_private.is_owner(group_id,(select auth.uid())) and created_by=(select auth.uid()));
create policy "doit daily members" on public.doit_daily for select to authenticated using(doit_private.is_member(group_id,(select auth.uid())));
create policy "doit own swaps" on public.doit_swaps for select to authenticated using(user_id=(select auth.uid()));
create policy "doit completion group view" on public.doit_completions for select to authenticated using(doit_private.is_member(group_id,(select auth.uid())));
create policy "doit ledger own view" on public.doit_xp_ledger for select to authenticated using(user_id=(select auth.uid()));
create policy "doit awards peers" on public.doit_achievements for select to authenticated using(user_id=(select auth.uid()) or doit_private.are_peers(user_id,(select auth.uid())));
create policy "doit shop view" on public.doit_shop for select to authenticated using(true);
create policy "doit owned own view" on public.doit_owned for select to authenticated using(user_id=(select auth.uid()));
create policy "doit comments group view" on public.doit_comments for select to authenticated using(exists(select 1 from public.doit_completions c where c.id=completion_id and doit_private.is_member(c.group_id,(select auth.uid()))));
create policy "doit comments create" on public.doit_comments for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.doit_completions c where c.id=completion_id and doit_private.is_member(c.group_id,(select auth.uid()))));
create policy "doit comments delete" on public.doit_comments for delete to authenticated using(user_id=(select auth.uid()));
create policy "doit reactions group view" on public.doit_reactions for select to authenticated using(exists(select 1 from public.doit_completions c where c.id=completion_id and doit_private.is_member(c.group_id,(select auth.uid()))));
create policy "doit reactions create" on public.doit_reactions for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.doit_completions c where c.id=completion_id and doit_private.is_member(c.group_id,(select auth.uid()))));
create policy "doit reactions delete" on public.doit_reactions for delete to authenticated using(user_id=(select auth.uid()));
create policy "doit alerts own read" on public.doit_alerts for select to authenticated using(user_id=(select auth.uid()));
create policy "doit alerts own update" on public.doit_alerts for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
grant select on public.doit_profiles,public.doit_groups,public.doit_members,public.doit_skills,public.doit_quests,public.doit_daily,public.doit_swaps,public.doit_completions,public.doit_xp_ledger,public.doit_achievements,public.doit_shop,public.doit_owned,public.doit_comments,public.doit_reactions,public.doit_alerts to authenticated;
revoke update on public.doit_profiles,public.doit_groups,public.doit_quests,public.doit_alerts from anon,authenticated;
grant update(display_name,blocked_tags,equipped_frame,equipped_theme) on public.doit_profiles to authenticated;
grant update(name,blocked_tags) on public.doit_groups to authenticated;
grant insert(title,description,skill_key,difficulty,minutes,xp,tags,group_id,created_by,active),update(title,description,skill_key,difficulty,minutes,xp,tags,active) on public.doit_quests to authenticated;
grant insert(completion_id,user_id,body),delete on public.doit_comments to authenticated;
grant insert(completion_id,user_id,emoji),delete on public.doit_reactions to authenticated;
grant update(read_at) on public.doit_alerts to authenticated;
create or replace function public.doit_ensure_profile(p_name text default null) returns public.doit_profiles
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); res public.doit_profiles;
begin
 if u is null then raise exception 'Sign in required'; end if;
 insert into public.doit_profiles(id,display_name)
 values(u,coalesce(nullif(left(trim(p_name),40),''),'Adventurer'))
 on conflict(id) do nothing;
 select * into res from public.doit_profiles where id=u;
 return res;
end $$;
create or replace function public.doit_create_group(p_name text,p_tags text[] default '{}') returns uuid
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); g uuid;
begin
 if u is null then raise exception 'Sign in required'; end if;
 if char_length(trim(p_name)) not between 2 and 64 then raise exception 'Group name length must be 2-64'; end if;
 perform public.doit_ensure_profile(null);
 insert into public.doit_groups(name,owner_id,blocked_tags) values(trim(p_name),u,coalesce(p_tags,'{}')) returning id into g;
 insert into public.doit_members(group_id,user_id,role) values(g,u,'owner');
 return g;
end $$;
create or replace function public.doit_join_group(p_code text) returns uuid
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); g uuid;
begin
 if u is null then raise exception 'Sign in required'; end if;
 select id into g from public.doit_groups where invite_code=upper(trim(p_code));
 if g is null then raise exception 'Invalid invitation code'; end if;
 perform public.doit_ensure_profile(null);
 if (select count(*) from public.doit_members where group_id=g)>=20 and not doit_private.is_member(g,u) then raise exception 'Group is full'; end if;
 insert into public.doit_members(group_id,user_id) values(g,u) on conflict do nothing;
 return g;
end $$;
create or replace function public.doit_prepare_daily(p_group uuid) returns date
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); d date:=(now() at time zone 'Europe/Lisbon')::date; i int; difficulty_name text; chosen uuid; grp public.doit_groups;
begin
 if u is null or not doit_private.is_member(p_group,u) then raise exception 'Not a group member'; end if;
 select * into grp from public.doit_groups where id=p_group;
 for i in 1..3 loop
  if not exists(select 1 from public.doit_daily where group_id=p_group and day=d and slot=i) then
   difficulty_name := (array['easy','medium','hard'])[i];
   select q.id into chosen from public.doit_quests q
    where q.active and q.difficulty=difficulty_name and (q.group_id is null or q.group_id=p_group)
      and not(q.tags && grp.blocked_tags)
      and not exists(select 1 from public.doit_daily past where past.group_id=p_group and past.quest_id=q.id and past.day>=d-45)
    order by md5(q.id::text||p_group::text||d::text) limit 1;
   if chosen is null then
    select q.id into chosen from public.doit_quests q where q.active and q.difficulty=difficulty_name and (q.group_id is null or q.group_id=p_group) and not(q.tags && grp.blocked_tags)
    order by md5(q.id::text||p_group::text||d::text) limit 1;
   end if;
   if chosen is not null then insert into public.doit_daily(group_id,day,slot,quest_id) values(p_group,d,i,chosen) on conflict do nothing; end if;
  end if;
 end loop;
 return d;
end $$;
create or replace function public.doit_swap_quest(p_group uuid,p_slot int) returns uuid
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); d date:=(now() at time zone 'Europe/Lisbon')::date; oldq public.doit_quests; nextq uuid; g public.doit_groups; p public.doit_profiles; is_free boolean;
begin
 if u is null or not doit_private.is_member(p_group,u) then raise exception 'Not a member'; end if;
 if p_slot not between 1 and 3 then raise exception 'Invalid quest slot'; end if;
 perform public.doit_prepare_daily(p_group);
 if exists(select 1 from public.doit_swaps where group_id=p_group and day=d and slot=p_slot and user_id=u) then raise exception 'Only one replacement per slot per day'; end if;
 if exists(select 1 from public.doit_completions where group_id=p_group and day=d and slot=p_slot and user_id=u) then raise exception 'Already completed'; end if;
 select q.* into oldq from public.doit_daily a join public.doit_quests q on q.id=a.quest_id where a.group_id=p_group and a.day=d and a.slot=p_slot;
 select * into g from public.doit_groups where id=p_group;
 select * into p from public.doit_profiles where id=u for update;
 is_free:=oldq.tags && p.blocked_tags;
 if not is_free and p.rerolls<1 then raise exception 'No reroll tokens available'; end if;
 select q.id into nextq from public.doit_quests q
 where q.active and q.difficulty=oldq.difficulty and (q.group_id is null or q.group_id=p_group)
 and q.id<>oldq.id and not(q.tags && g.blocked_tags) and not(q.tags && p.blocked_tags)
 and not exists(select 1 from public.doit_daily a where a.group_id=p_group and a.day=d and a.quest_id=q.id)
 order by md5(q.id::text||u::text||d::text) limit 1;
 if nextq is null then raise exception 'No suitable alternative found'; end if;
 insert into public.doit_swaps(group_id,day,slot,user_id,quest_id,kind) values(p_group,d,p_slot,u,nextq,case when is_free then 'accessibility' else 'reroll' end);
 if not is_free then update public.doit_profiles set rerolls=rerolls-1 where id=u; end if;
 return nextq;
end $$;
create or replace function public.doit_complete(p_group uuid,p_slot int,p_photo text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); d date:=(now() at time zone 'Europe/Lisbon')::date; q public.doit_quests; qid uuid; awarded int:=0; bonus int:=0; n int; current_streak int; old_day date; old_freezes int;
begin
 if u is null or not doit_private.is_member(p_group,u) then raise exception 'Not a group member'; end if;
 if p_slot not between 1 and 3 then raise exception 'Invalid quest slot'; end if;
 perform public.doit_prepare_daily(p_group);
 if exists(select 1 from public.doit_completions where user_id=u and group_id=p_group and day=d and slot=p_slot) then raise exception 'Already completed'; end if;
 if p_photo not like (p_group::text||'/'||u::text||'/%') then raise exception 'Invalid photo path'; end if;
 if not exists(select 1 from storage.objects where bucket_id='doit-photos' and name=p_photo and owner_id=u::text and created_at>now()-interval '2 days') then raise exception 'Photo upload not found'; end if;
 select coalesce((select s.quest_id from public.doit_swaps s where s.group_id=p_group and s.user_id=u and s.day=d and s.slot=p_slot), a.quest_id)
 into qid from public.doit_daily a where a.group_id=p_group and a.day=d and a.slot=p_slot;
 if qid is null then raise exception 'Quest not available'; end if;
 select * into q from public.doit_quests where id=qid;
 insert into public.doit_xp_ledger(user_id,day,quest_id,source,xp,skill_key)
 values(u,d,qid,'quest',q.xp,q.skill_key) on conflict do nothing;
 if found then awarded:=q.xp; end if;
 insert into public.doit_completions(user_id,group_id,day,slot,quest_id,photo_path,xp_awarded)
 values(u,p_group,d,p_slot,qid,p_photo,awarded);
 update public.doit_profiles set xp=xp+awarded, coins=coins+case when awarded>0 then greatest(5,round(awarded::numeric/5)::integer) else 0 end where id=u;
 select last_day,streak,freezes into old_day,current_streak,old_freezes from public.doit_profiles where id=u for update;
 if old_day is distinct from d then
  if old_day=d-1 then current_streak:=current_streak+1;
  elsif old_day=d-2 and old_freezes>0 then
   current_streak:=current_streak+1;
   update public.doit_profiles set freezes=freezes-1 where id=u;
  else current_streak:=1;
  end if;
  update public.doit_profiles set streak=current_streak,last_day=d where id=u;
  if current_streak>0 and current_streak%7=0 then update public.doit_profiles set freezes=least(2,freezes+1) where id=u; end if;
 end if;
 select count(*) into n from public.doit_completions where user_id=u and group_id=p_group and day=d;
 if n=3 then
  select round(sum(q2.xp)::numeric*0.2)::integer into bonus from public.doit_completions c join public.doit_quests q2 on q2.id=c.quest_id where c.user_id=u and c.group_id=p_group and c.day=d;
  insert into public.doit_xp_ledger(user_id,day,source,xp) values(u,d,'daily_bonus',bonus) on conflict do nothing;
  if found then update public.doit_profiles set xp=xp+bonus,coins=coins+30 where id=u;
  else bonus:=0; end if;
 end if;
 select count(*) into n from public.doit_completions where user_id=u;
 if n=1 then insert into public.doit_achievements(user_id,code) values(u,'first_steps') on conflict do nothing; end if;
 if n>=10 then insert into public.doit_achievements(user_id,code) values(u,'quest_10') on conflict do nothing; end if;
 if n>=25 then insert into public.doit_achievements(user_id,code) values(u,'quest_25') on conflict do nothing; end if;
 if n>=100 then insert into public.doit_achievements(user_id,code) values(u,'quest_100') on conflict do nothing; end if;
 if current_streak>=7 then insert into public.doit_achievements(user_id,code) values(u,'streak_7') on conflict do nothing; end if;
 if n>0 and n%10=0 then update public.doit_profiles set rerolls=least(3,rerolls+1) where id=u; end if;
 insert into public.doit_alerts(user_id,text)
 select m.user_id,coalesce((select display_name from public.doit_profiles where id=u),'A friend')||' completed '||q.title
 from public.doit_members m where m.group_id=p_group and m.user_id<>u;
 return jsonb_build_object('xp',awarded,'bonus',bonus,'coins',case when awarded>0 then greatest(5,round(awarded::numeric/5)::integer) else 0 end);
end $$;
create or replace function public.doit_buy(p_item text) returns void
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); price_value int; balance int;
begin
 if u is null then raise exception 'Sign in required'; end if;
 select price into price_value from public.doit_shop where id=p_item;
 if price_value is null then raise exception 'Unknown item'; end if;
 if exists(select 1 from public.doit_owned where user_id=u and item_id=p_item) then raise exception 'Already owned'; end if;
 select coins into balance from public.doit_profiles where id=u for update;
 if balance<price_value then raise exception 'Not enough coins'; end if;
 update public.doit_profiles set coins=coins-price_value where id=u;
 insert into public.doit_owned(user_id,item_id) values(u,p_item);
end $$;
create or replace function public.doit_equip(p_item text) returns void
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); k text;
begin
 if u is null then raise exception 'Sign in required'; end if;
 select kind into k from public.doit_shop where id=p_item;
 if not exists(select 1 from public.doit_owned where user_id=u and item_id=p_item) then raise exception 'Not owned'; end if;
 if k='frame' then update public.doit_profiles set equipped_frame=p_item where id=u;
 elsif k='theme' then update public.doit_profiles set equipped_theme=p_item where id=u; end if;
end $$;
revoke all on function public.doit_ensure_profile(text),public.doit_create_group(text,text[]),public.doit_join_group(text),public.doit_prepare_daily(uuid),public.doit_swap_quest(uuid,integer),public.doit_complete(uuid,integer,text),public.doit_buy(text),public.doit_equip(text) from public,anon;
grant execute on function public.doit_ensure_profile(text),public.doit_create_group(text,text[]),public.doit_join_group(text),public.doit_prepare_daily(uuid),public.doit_swap_quest(uuid,integer),public.doit_complete(uuid,integer,text),public.doit_buy(text),public.doit_equip(text) to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('doit-photos','doit-photos',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
create policy "doit photo upload member only" on storage.objects for insert to authenticated with check(
 bucket_id='doit-photos' and split_part(name,'/',2)=(select auth.uid())::text
 and exists(select 1 from public.doit_members m where m.group_id::text=split_part(name,'/',1) and m.user_id=(select auth.uid()))
);
create policy "doit photo read group" on storage.objects for select to authenticated using(
 bucket_id='doit-photos' and exists(select 1 from public.doit_members m where m.group_id::text=split_part(name,'/',1) and m.user_id=(select auth.uid()))
);
create policy "doit photo delete own" on storage.objects for delete to authenticated using(
 bucket_id='doit-photos' and owner_id=(select auth.uid())::text and split_part(name,'/',2)=(select auth.uid())::text
);
insert into public.doit_shop(id,title,kind,price,icon) values
('frame-forest','Forest Frame','frame',100,'🌿'),
('frame-sunset','Sunset Frame','frame',180,'🌅'),
('frame-cobalt','Cobalt Frame','frame',260,'💠'),
('frame-gold','Golden Frame','frame',500,'✨'),
('theme-forest','Forest Theme','theme',150,'🌲'),
('theme-lavender','Lavender Theme','theme',200,'💜'),
('theme-night','Midnight Theme','theme',350,'🌙'),
('theme-sunrise','Sunrise Theme','theme',450,'☀️')
on conflict(id) do nothing;

insert into public.doit_skills(key,category,name,icon) values ('cooking','Cooking','Cooking','utensils'),('baking','Cooking','Baking','cake-slice'),('nutrition','Cooking','Nutrition','salad'),('presentation','Cooking','Food Presentation','chef-hat'),('drawing','Creativity','Drawing','pencil'),('photography','Creativity','Photography','camera'),('writing','Creativity','Writing','book-open'),('crafts','Creativity','Crafts','scissors'),('science','Knowledge','Science','flask-conical'),('history','Knowledge','History','landmark'),('languages','Knowledge','Languages','languages'),('philosophy','Knowledge','Philosophy','brain'),('strength','Physical','Strength','dumbbell'),('mobility','Physical','Mobility','activity'),('endurance','Physical','Endurance','footprints'),('coordination','Physical','Coordination','target'),('diy','Practical Life','DIY','hammer'),('organization','Practical Life','Organization','archive'),('maintenance','Practical Life','Home Maintenance','wrench'),('problems','Practical Life','Problem Solving','lightbulb'),('communication','Social','Communication','messages-square'),('kindness','Social','Kindness','heart-handshake'),('collaboration','Social','Collaboration','users'),('confidence','Social','Confidence','megaphone'),('nature','Outdoors','Nature','leaf'),('gardening','Outdoors','Gardening','flower-2'),('exploration','Outdoors','Exploration','map'),('navigation','Outdoors','Navigation','compass'),('programming','Technology','Programming','code'),('design','Technology','Digital Creativity','paintbrush'),('literacy','Technology','Digital Literacy','shield'),('tools','Technology','Digital Tools','laptop')
on conflict(key) do nothing;
insert into public.doit_quests(title,description,skill_key,difficulty,minutes,xp,tags) values
('Build a balanced snack','Make a snack combining at least two food groups and photograph your creation.','cooking','easy',10,25,ARRAY['kitchen']::text[]),
('Measure a baking ingredient','Practice accurately weighing or measuring three baking ingredients. Photograph your setup.','baking','easy',15,35,ARRAY['kitchen']::text[]),
('Read a nutrition label','Compare the ingredients and nutrition panels of two foods. Photograph the labels.','nutrition','easy',10,25,ARRAY[]::text[]),
('Plate an everyday meal','Arrange a meal as if serving it in a cafe. Take a photo before eating.','presentation','easy',10,25,ARRAY['kitchen']::text[]),
('Sketch a household object','Choose any nearby object and draw it for ten minutes. Photograph your drawing.','drawing','easy',10,25,ARRAY[]::text[]),
('Capture a reflection','Take an original photo using a reflection, such as a window, puddle, or mirror.','photography','easy',10,25,ARRAY[]::text[]),
('Write a six-line story','Write a complete miniature story in exactly six lines. Photograph your handwritten page.','writing','easy',10,25,ARRAY[]::text[]),
('Make a paper bookmark','Create a functional paper bookmark using any materials you already have. Photograph it.','crafts','easy',15,35,ARRAY[]::text[]),
('Investigate a science question','Find a trustworthy explanation of a question about the natural world and photograph your notes.','science','easy',10,25,ARRAY['internet']::text[]),
('Discover a historical fact','Research an event that occurred on today''s date and write three facts about it. Photograph your notes.','history','easy',15,35,ARRAY['internet']::text[]),
('Learn five foreign words','Learn five useful words in a language you don''t speak. Write them down and photograph them.','languages','easy',10,25,ARRAY['internet']::text[]),
('Explore a thought experiment','Read one famous thought experiment, write your position in two sentences, and photograph it.','philosophy','easy',10,25,ARRAY['internet']::text[]),
('Practice a bodyweight movement','Complete a gentle bodyweight movement you can safely perform. Photograph your workout notes afterward.','strength','easy',10,25,ARRAY['exercise']::text[]),
('Try a gentle mobility routine','Perform five to ten minutes of comfortable joint mobility. Photograph your routine checklist.','mobility','easy',10,25,ARRAY['exercise']::text[]),
('Take a brisk walk','Go for a comfortable walk and photograph something interesting along the route.','endurance','easy',15,35,ARRAY['outdoors','exercise']::text[]),
('Practice juggling','Practice a simple toss-and-catch pattern with a soft object. Photograph the practice setup.','coordination','easy',10,25,ARRAY['exercise']::text[]),
('Fix one small annoyance','Repair or improve a minor everyday object using safe tools. Photograph the result.','diy','easy',15,35,ARRAY['tools']::text[]),
('Organize one drawer','Tidy one small drawer or shelf and photograph the organized result.','organization','easy',10,25,ARRAY[]::text[]),
('Clean a neglected surface','Find and clean one commonly forgotten surface. Photograph the finished result.','maintenance','easy',10,25,ARRAY[]::text[]),
('Solve a logic puzzle','Try a short logic puzzle and photograph your working or solution.','problems','easy',10,25,ARRAY[]::text[]),
('Send a thoughtful question','Ask a friend or family member an interesting open-ended question. Photograph a note describing what you learned, without sharing private messages.','communication','easy',10,25,ARRAY[]::text[]),
('Leave an encouraging note','Write a genuine encouraging note for someone and photograph it before giving it to them.','kindness','easy',10,25,ARRAY[]::text[]),
('Plan something together','Agree on a small shared activity with a friend. Photograph the written plan, without private details.','collaboration','easy',10,25,ARRAY[]::text[]),
('Practice a short introduction','Write and rehearse a 30-second self-introduction. Photograph your speaking notes.','confidence','easy',10,25,ARRAY[]::text[]),
('Observe a tree','Spend a few minutes noticing a tree''s features and photograph one distinctive detail.','nature','easy',15,35,ARRAY['outdoors']::text[]),
('Care for a plant','Check a plant''s needs and perform appropriate care. Photograph it afterward.','gardening','easy',10,25,ARRAY['plant']::text[]),
('Explore an unfamiliar street','Walk safely down a street you rarely visit and photograph something you discover.','exploration','easy',15,35,ARRAY['outdoors']::text[]),
('Draw a simple route map','Draw a map from memory showing a familiar route. Photograph the map.','navigation','easy',10,25,ARRAY[]::text[]),
('Write a tiny program','Use an online coding editor to run a program that prints your own message. Photograph the result.','programming','easy',15,35,ARRAY['computer','internet']::text[]),
('Create a colour palette','Choose five colours for an imaginary brand and photograph or screenshot your palette.','design','easy',15,35,ARRAY['computer']::text[]),
('Check one privacy setting','Review a privacy option on one of your devices and photograph a harmless settings summary, hiding sensitive information.','literacy','easy',10,25,ARRAY['device']::text[]),
('Learn one keyboard shortcut','Find a useful keyboard shortcut you didn''t know and demonstrate it. Photograph your notes.','tools','easy',10,25,ARRAY['computer']::text[]),
('Cook a new recipe','Cook a complete recipe you have never tried before. Photograph the final dish.','cooking','medium',35,80,ARRAY['kitchen']::text[]),
('Bake something simple','Bake cookies, bread, muffins or a similar item from a recipe and photograph the result.','baking','medium',40,90,ARRAY['oven','kitchen']::text[]),
('Design a balanced lunch','Plan a practical nutritious lunch with portions and ingredients. Photograph your handwritten plan.','nutrition','medium',25,60,ARRAY[]::text[]),
('Create a restaurant-style plate','Use contrast, height and colour to plate a meal beautifully. Photograph it.','presentation','medium',30,70,ARRAY['kitchen']::text[]),
('Draw a room in perspective','Sketch a corner of a room using basic perspective lines. Photograph the finished sketch.','drawing','medium',30,70,ARRAY[]::text[]),
('Create a three-photo series','Take three photographs on a single theme, using different framing. Submit a collage photo.','photography','medium',30,70,ARRAY['camera']::text[]),
('Write a 300-word scene','Write a short dramatic scene with a beginning, turning point and ending. Photograph your page.','writing','medium',30,70,ARRAY[]::text[]),
('Build an origami object','Follow instructions to fold a paper object you have never made before. Photograph the result.','crafts','medium',40,90,ARRAY[]::text[]),
('Run a safe mini-experiment','Choose a harmless household observation, form a hypothesis and record the result. Photograph your written findings.','science','medium',30,70,ARRAY[]::text[]),
('Research a historical figure','Find three reliable sources on a lesser-known historical figure. Create and photograph a five-point timeline.','history','medium',30,70,ARRAY['internet']::text[]),
('Learn basic travel phrases','Learn and rehearse ten phrases in an unfamiliar language. Photograph your phrase sheet.','languages','medium',30,70,ARRAY['internet']::text[]),
('Compare two positions','Read two contrasting short philosophical arguments and write a paragraph explaining their disagreement. Photograph it.','philosophy','medium',30,70,ARRAY['internet']::text[]),
('Complete a strength session','Perform a safe strength workout suited to your ability and photograph the completed routine notes.','strength','medium',30,70,ARRAY['exercise']::text[]),
('Build a personal mobility flow','Design and perform a comfortable 15-minute mobility routine. Photograph the flow written out.','mobility','medium',25,60,ARRAY['exercise']::text[]),
('Explore a longer walking route','Follow a safe walking route at a comfortable pace. Photograph a landmark you encounter.','endurance','medium',35,80,ARRAY['outdoors','exercise']::text[]),
('Learn a new movement pattern','Practice a new low-risk coordination exercise for twenty minutes. Photograph your progress notes.','coordination','medium',30,70,ARRAY['exercise']::text[]),
('Build a small practical object','Make a simple object using safe household materials. Photograph the finished result.','diy','medium',40,90,ARRAY['tools']::text[]),
('Redesign a storage space','Reorganize a shelf, desk or cabinet around a clear purpose. Photograph the outcome.','organization','medium',30,70,ARRAY[]::text[]),
('Carry out basic upkeep','Perform a safe household maintenance task you have postponed. Photograph the completed work.','maintenance','medium',30,70,ARRAY['tools']::text[]),
('Solve a challenging puzzle','Work through a multi-step logic or number puzzle. Photograph your reasoning.','problems','medium',30,70,ARRAY[]::text[]),
('Have an intentional conversation','Ask someone about a topic they care about and practise attentive listening. Photograph a private reflection note, not the person.','communication','medium',30,70,ARRAY[]::text[]),
('Make a useful gesture','Do something practical and thoughtful for someone, then photograph a non-identifying part of your contribution.','kindness','medium',30,70,ARRAY[]::text[]),
('Make something with a friend','Collaborate on a small creative or practical task and photograph the result with consent.','collaboration','medium',40,90,ARRAY['friend']::text[]),
('Rehearse a mini-presentation','Prepare and rehearse a two-minute explanation of something interesting. Photograph your outline.','confidence','medium',30,70,ARRAY[]::text[]),
('Identify three plants','Observe three plants safely and identify them using a reliable reference. Photograph a labelled sketch or collage.','nature','medium',30,70,ARRAY['outdoors']::text[]),
('Start a windowsill project','Prepare a small container for a suitable plant or herb. Photograph the setup.','gardening','medium',35,80,ARRAY['plant']::text[]),
('Visit a new local spot','Discover a nearby park, gallery, market or quiet public space you haven''t visited. Photograph one feature.','exploration','medium',40,90,ARRAY['outdoors']::text[]),
('Navigate using a paper map','Plan a short safe walk with a map and follow it. Photograph your annotated route.','navigation','medium',30,70,ARRAY['outdoors']::text[]),
('Build a small interactive script','Write a tiny script that accepts input and produces an output. Photograph a successful test.','programming','medium',45,95,ARRAY['computer','internet']::text[]),
('Design a simple event poster','Create a clean one-page poster for a fictional event. Photograph or screenshot it.','design','medium',40,90,ARRAY['computer']::text[]),
('Audit your digital security','Review passwords, two-factor authentication and app permissions. Photograph a checklist without exposing any secrets.','literacy','medium',30,70,ARRAY['device']::text[]),
('Learn a new software tool','Learn three features in an app you rarely use, produce a tiny example and photograph or screenshot it.','tools','medium',30,70,ARRAY['computer']::text[]),
('Prepare a three-course menu','Plan and prepare three simple courses for a meal. Photograph your plated creations.','cooking','hard',75,185,ARRAY['kitchen']::text[]),
('Master a new baking technique','Attempt an unfamiliar baking technique using a detailed recipe. Photograph the result and notes.','baking','hard',90,220,ARRAY['oven','kitchen']::text[]),
('Create a weekly meal plan','Build a realistic seven-day meal plan with varied, balanced meals and a shopping list. Photograph it.','nutrition','hard',70,175,ARRAY[]::text[]),
('Style a food photography scene','Prepare food and arrange props and lighting for a polished food photograph. Submit the result.','presentation','hard',70,175,ARRAY['kitchen']::text[]),
('Draw a detailed still life','Arrange three objects and create a detailed drawing with light and shadow. Photograph your artwork.','drawing','hard',70,175,ARRAY[]::text[]),
('Tell a story through five photos','Produce five original photographs that together tell a simple story. Submit a collage.','photography','hard',80,195,ARRAY['camera']::text[]),
('Write a complete short story','Create and revise a 700-word short story with a clear conclusion. Photograph the finished pages.','writing','hard',75,185,ARRAY[]::text[]),
('Create a handmade gift','Design and make a small personal gift from inexpensive materials. Photograph the finished item.','crafts','hard',75,185,ARRAY[]::text[]),
('Explain a scientific concept visually','Research a scientific idea and create a hand-drawn explainer with a diagram and examples. Photograph it.','science','hard',70,175,ARRAY['internet']::text[]),
('Reconstruct an event timeline','Research a historical event, compare sources and illustrate a ten-step timeline. Photograph it.','history','hard',75,185,ARRAY['internet']::text[]),
('Hold a basic foreign-language dialogue','Learn and practise a 15-line scripted conversation in a foreign language. Photograph your script and reflection.','languages','hard',70,175,ARRAY['internet']::text[]),
('Write a reasoned philosophical essay','Choose a challenging everyday ethical question and write a structured 500-word argument. Photograph the draft.','philosophy','hard',75,185,ARRAY[]::text[]),
('Design and finish a full workout','Plan and perform a safe individualized full-body workout, and photograph your completed log.','strength','hard',70,175,ARRAY['exercise']::text[]),
('Learn a complete movement routine','Research, practise and perform a safe mobility sequence within your comfortable range. Photograph your routine notes.','mobility','hard',65,160,ARRAY['exercise']::text[]),
('Complete a personal distance challenge','Choose a realistic longer walking distance based on your capacity and complete it safely. Photograph a landmark on the route.','endurance','hard',90,220,ARRAY['outdoors','exercise']::text[]),
('Learn a complex coordination sequence','Practise a challenging but safe multi-step movement or juggling sequence. Photograph your practice notes.','coordination','hard',70,175,ARRAY['exercise']::text[]),
('Build a useful household organizer','Design and make a safe, useful organizer from available materials. Photograph the finished object.','diy','hard',90,220,ARRAY['tools']::text[]),
('Reorganize an entire workspace','Plan, declutter and reorganize your desk or working area, then photograph the result.','organization','hard',70,175,ARRAY[]::text[]),
('Complete a household care project','Tackle a substantial safe cleaning or maintenance project using appropriate tools. Photograph the outcome.','maintenance','hard',75,185,ARRAY['tools']::text[]),
('Solve a multi-stage challenge','Find and solve a difficult multi-step reasoning challenge. Photograph a clear explanation of your method.','problems','hard',75,185,ARRAY[]::text[]),
('Interview someone about their expertise','With their consent, ask someone ten thoughtful questions about a skill they know. Write and photograph a non-identifying summary.','communication','hard',75,185,ARRAY['friend']::text[]),
('Plan and deliver a meaningful favour','Identify a genuine need and spend time offering practical help. Photograph the non-private outcome.','kindness','hard',70,175,ARRAY[]::text[]),
('Co-create a mini project','Work with a friend to create a small finished product or event plan. Photograph it with everyone''s consent.','collaboration','hard',90,220,ARRAY['friend']::text[]),
('Present a short lesson to someone','Prepare and deliver a five-minute lesson on something you know. Photograph your lesson materials.','confidence','hard',75,185,ARRAY['friend']::text[]),
('Create a field observation journal','Spend time safely outdoors and record observations of at least six natural features. Photograph your journal.','nature','hard',80,195,ARRAY['outdoors']::text[]),
('Build a small indoor garden','Plan and set up a small indoor herb or plant collection, using what is available. Photograph it.','gardening','hard',90,220,ARRAY['plant']::text[]),
('Explore a new neighbourhood','Plan a safe visit to a neighbourhood you rarely explore and document five discoveries in a photo collage.','exploration','hard',90,220,ARRAY['outdoors']::text[]),
('Plan and complete a discovery trail','Create a route visiting three unfamiliar local landmarks and follow it safely. Photograph your route map.','navigation','hard',75,185,ARRAY['outdoors']::text[]),
('Build a useful tiny web app','Create a small interactive webpage or utility and demonstrate it working. Photograph or screenshot the result.','programming','hard',90,220,ARRAY['computer','internet']::text[]),
('Build a miniature brand identity','Design a fictional brand''s logo, palette and promotional banner. Submit a collage.','design','hard',80,195,ARRAY['computer']::text[]),
('Create a privacy improvement plan','Audit your digital privacy and implement at least three safer settings. Photograph a summary checklist without sensitive data.','literacy','hard',75,185,ARRAY['device']::text[]),
('Automate a repetitive digital task','Create a simple safe automation in a spreadsheet or productivity app and photograph the result.','tools','hard',80,195,ARRAY['computer']::text[]);
