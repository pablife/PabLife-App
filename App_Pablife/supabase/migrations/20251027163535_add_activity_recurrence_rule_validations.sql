ALTER TABLE public.tb_activity_recurrence_rules
ADD CONSTRAINT ck_activity_recur_by_week_day_valid
CHECK (public.int2_array_all_between(by_week_day, 0, 6, TRUE)),
ADD CONSTRAINT ck_activity_recur_by_week_day_unique
CHECK (public.int2_array_unique(by_week_day)),
ADD CONSTRAINT ck_activity_recur_timezone_valid
CHECK (public.tz_valid(timezone));
