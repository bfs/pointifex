CREATE OR REPLACE FUNCTION pointify_geom (
  geom geometry,
  grid_size int
  )
RETURNS setof geometry AS
$body$
  DECLARE

  metric_geom geometry;
  simplified_metric_geom geometry;
  pt geometry;

  metric_srid int;
  orig_srid int;
 
  Xmin double precision;
  Xmax double precision;
  Ymax double precision;
  X double precision;
  Y double precision;


  BEGIN

    metric_srid := utmzone(st_centroid(geom));
    orig_srid := ST_SRID(geom);
    metric_geom := ST_Transform(geom, metric_srid); 

    Xmin := ST_XMin(metric_geom);
    Xmax := ST_XMax(metric_geom);
    Ymax := ST_YMax(metric_geom);
    Y := ST_YMin(metric_geom);

    simplified_metric_geom :=ST_SimplifyPreserveTopology(metric_geom,grid_size/2.0);
  
    FOR pt in select (ST_DumpPoints(st_segmentize(simplified_metric_geom,grid_size))).geom LOOP
      IF ST_Intersects(pt,metric_geom) THEN
        RETURN NEXT ST_Transform(pt,orig_srid);
      END IF;
    END LOOP;

    <<yloop>>
    LOOP
      IF (Y > Ymax) THEN 
        EXIT;
      END IF;

      X := Xmin;
      <<xloop>>
      LOOP
        IF (X > Xmax) THEN
          EXIT;
        END IF;

        pt := ST_SetSRID(ST_MakePoint(X,Y),metric_srid);

        IF (ST_Intersects(pt,metric_geom)) THEN
          RETURN NEXT ST_Transform(pt,orig_srid);
        END IF;
        
        X := X + grid_size;
      END LOOP xloop;
      Y := Y + grid_size;
    END LOOP yloop;


  EXCEPTION WHEN others THEN
   raise notice 'Failed to pointify geometry';
   raise notice '% %', SQLERRM, SQLSTATE;
   RETURN next ST_Centroid(geom);
  END;
  $body$
  LANGUAGE 'plpgsql';
