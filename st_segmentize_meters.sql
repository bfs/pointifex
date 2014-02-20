CREATE OR REPLACE FUNCTION st_segmentize_meters(geometry, double precision)
  RETURNS geometry AS
$BODY$
DECLARE
orig_srid int;
utm_srid int;
BEGIN

orig_srid:= ST_SRID($1);
utm_srid:= utmzone(ST_Centroid($1));
RETURN ST_transform(ST_Segmentize(ST_transform($1, utm_srid), $2), orig_srid);
EXCEPTION WHEN others THEN
  raise notice 'Failed to segmentize geometry';
  raise notice '% %', SQLERRM, SQLSTATE;
  RETURN $1;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
