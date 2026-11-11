-- Ilustrações do bebê nas semanas de referência (8, 12, ..., 40), enviadas ao
-- bucket público pregnancy-illustrations. As outras semanas usam a imagem
-- da semana de referência mais próxima (ref_week de get_my_pregnancy).
-- Só preenche image_url onde ainda está vazio.

update public.tb_pregnancy_weeks w
   set image_url = 'https://codfvqwqsypxqewlcrcj.supabase.co/storage/v1/object/public/pregnancy-illustrations/semana-'
                   || lpad(w.week::text, 2, '0') || '.png'
 where w.week in (8, 12, 16, 20, 24, 28, 32, 36, 40)
   and w.image_url is null;
