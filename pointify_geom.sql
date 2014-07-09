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
  simple_geom geometry;

  metric_srid int;
  orig_srid int;
 
  Xmin double precision;
  Xmax double precision;
  Ymax double precision;
  X double precision;
  Y double precision;


  BEGIN

    FOR simple_geom in select (ST_Dump(geom)).geom LOOP
      
      BEGIN
        metric_srid := utmzone(st_centroid(simple_geom));
        orig_srid := ST_SRID(simple_geom);
        metric_geom := ST_Transform(simple_geom, metric_srid); 

        Xmin := ST_XMin(metric_geom);
        Xmax := ST_XMax(metric_geom);
        Ymax := ST_YMax(metric_geom);
        Y := ST_YMin(metric_geom);

        simplified_metric_geom :=ST_MakeValid(ST_SimplifyPreserveTopology(metric_geom,grid_size/2.0));

        IF ST_IsValid(simplified_metric_geom)='f' THEN
          simplified_metric_geom:=metric_geom;
        END IF;
      
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
       raise notice 'Failed to pointify geometry %', ST_AsText(simple_geom);
       raise notice '% %', SQLERRM, SQLSTATE;
       RETURN next ST_Centroid(simple_geom);
      END;
    END LOOP;
  END; 
  $body$
  LANGUAGE 'plpgsql';
