ALTER TABLE public.tb_appointment_recurrence_rules
ADD CONSTRAINT ck_appointment_recur_timezone_valid
CHECK (public.tz_valid(timezone));
