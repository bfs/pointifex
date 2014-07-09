CREATE OR REPLACE FUNCTION st_resize_segments_meters(input_geom geometry, no_smaller_than int, no_bigger_than int)
  RETURNS geometry AS
$BODY$
DECLARE
orig_srid int;
utm_srid int;
simple_geom geometry;
metric_geom geometry;
result_geom geometry;
result_geom_collection geometry[];
c int;
BEGIN
  c := 0;
  FOR simple_geom in select (ST_Dump(input_geom)).geom LOOP
    BEGIN
      orig_srid:= ST_SRID(simple_geom);
      utm_srid:= utmzone(ST_Centroid(simple_geom));
      metric_geom := ST_Transform(simple_geom, utm_srid);

      result_geom := ST_Segmentize(ST_SimplifyPreserveTopology(metric_geom, no_smaller_than),no_bigger_than);
      result_geom_collection[c] := ST_Transform(ST_Segmentize(result_geom,no_bigger_than),orig_srid);

    EXCEPTION WHEN others THEN
      raise notice 'Failed to resize segments in geometry %', ST_AsText(simple_geom);
      raise notice '% %', SQLERRM, SQLSTATE;
      result_geom_collection[c] := simple_geom;
    END;
    c := c + 1;
  END LOOP;
  RETURN ST_Collect(result_geom_collection);
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
