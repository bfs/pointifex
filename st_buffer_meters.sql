-- Function: st_buffer_meters(geometry, double precision)
CREATE OR REPLACE FUNCTION st_buffer_meters(geometry, double precision)
  RETURNS geometry AS
$BODY$
DECLARE
orig_srid int;
utm_srid int;
BEGIN
orig_srid:= ST_SRID($1);
utm_srid:= utmzone(ST_Centroid($1));
RETURN ST_transform(ST_Buffer(ST_transform($1, utm_srid), $2), orig_srid);
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
