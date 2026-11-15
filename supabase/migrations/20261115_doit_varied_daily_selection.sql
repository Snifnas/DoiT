-- Prioritise three *different experiences*, not three near-identical assignments.
-- The daily result is shared by every member of a group and stable for that day.
CREATE OR REPLACE FUNCTION public.doit_prepare_daily(p_group uuid)
RETURNS date
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  u uuid := auth.uid();
  d date := (now() at time zone 'Europe/Lisbon')::date;
  i integer;
  difficulty_name text;
  chosen uuid;
  grp public.doit_groups;
BEGIN
  IF u IS NULL OR NOT doit_private.is_member(p_group,u)
    THEN RAISE EXCEPTION 'Not a group member';
  END IF;

  SELECT * INTO grp FROM public.doit_groups WHERE id=p_group;

  FOR i IN 1..3 LOOP
    IF NOT EXISTS (
      SELECT 1 FROM public.doit_daily
      WHERE group_id=p_group AND day=d AND slot=i
    ) THEN
      difficulty_name := (ARRAY['easy','medium','hard'])[i];

      SELECT q.id INTO chosen
      FROM public.doit_quests q
      JOIN public.doit_skills sk ON sk.key=q.skill_key
      WHERE q.active
        AND q.difficulty=difficulty_name
        AND (q.group_id IS NULL OR q.group_id=p_group)
        AND NOT (q.tags && grp.blocked_tags)
        AND NOT EXISTS (
          SELECT 1 FROM public.doit_daily cur
          WHERE cur.group_id=p_group AND cur.day=d AND cur.quest_id=q.id
        )
        AND NOT EXISTS (
          SELECT 1 FROM public.doit_daily old
          WHERE old.group_id=p_group AND old.quest_id=q.id
          AND old.day>=d-45 AND old.day<d
        )
      ORDER BY
        -- Prefer a different category for each of today's three quests.
        CASE WHEN EXISTS (
          SELECT 1
          FROM public.doit_daily cur
          JOIN public.doit_quests chosen_q ON chosen_q.id=cur.quest_id
          JOIN public.doit_skills chosen_sk ON chosen_sk.key=chosen_q.skill_key
          WHERE cur.group_id=p_group AND cur.day=d
            AND chosen_sk.category=sk.category
        ) THEN 1 ELSE 0 END,
        md5(q.id::text || p_group::text || d::text)
      LIMIT 1;

      IF chosen IS NULL THEN
        -- Library exhausted for this difficulty: allow older repeats but
        -- still avoid a duplicate on the same day and prefer new categories.
        SELECT q.id INTO chosen
        FROM public.doit_quests q
        JOIN public.doit_skills sk ON sk.key=q.skill_key
        WHERE q.active
          AND q.difficulty=difficulty_name
          AND (q.group_id IS NULL OR q.group_id=p_group)
          AND NOT (q.tags && grp.blocked_tags)
          AND NOT EXISTS (
            SELECT 1 FROM public.doit_daily cur
            WHERE cur.group_id=p_group AND cur.day=d AND cur.quest_id=q.id
          )
        ORDER BY
          CASE WHEN EXISTS (
            SELECT 1
            FROM public.doit_daily cur
            JOIN public.doit_quests chosen_q ON chosen_q.id=cur.quest_id
            JOIN public.doit_skills chosen_sk ON chosen_sk.key=chosen_q.skill_key
            WHERE cur.group_id=p_group AND cur.day=d
              AND chosen_sk.category=sk.category
          ) THEN 1 ELSE 0 END,
          md5(q.id::text || p_group::text || d::text)
        LIMIT 1;
      END IF;

      IF chosen IS NOT NULL THEN
        INSERT INTO public.doit_daily(group_id,day,slot,quest_id)
        VALUES(p_group,d,i,chosen)
        ON CONFLICT DO NOTHING;
      END IF;
    END IF;
  END LOOP;
  RETURN d;
END
$$;