CREATE OR REPLACE FUNCTION gridify_geom (
	geom geometry,
	grid_size int
	)
RETURNS setof geometry AS
$body$
	DECLARE
  
  metric_geom geometry;
  current_grid geometry;
  
  metric_srid int;
  orig_srid int;
  
  Xmin double precision;
  Xmax double precision;
  Ymax double precision;
  X double precision;
  Y double precision;


  BEGIN
		metric_srid := utmzone(ST_Centroid(geom));
	  metric_geom := ST_Transform(geom, metric_srid); 
    orig_srid := ST_SRID(geom);
	  Xmin := ST_XMin(metric_geom);
	  Xmax := ST_XMax(metric_geom);
	  Ymax := ST_YMax(metric_geom);

	  Y := ST_YMin(metric_geom);

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


		    current_grid := ST_MakeValid(ST_GeomFromText('POLYGON(('||X||' '||Y||', '||(X+grid_size)||' '||Y||', '||(X+grid_size)||' '||(Y+grid_size)||', '||X||' '||(Y+grid_size)||', '||X||' '||Y||'))', metric_srid));
		    
			  IF (ST_Intersects(current_grid,metric_geom)) THEN
			  	RETURN NEXT ST_Transform(st_intersection(current_grid,metric_geom),orig_srid);
			  END IF;
			  
	    	X := X + grid_size;
	    END LOOP xloop;
	    Y := Y + grid_size;
	  END LOOP yloop;

  EXCEPTION WHEN others THEN
   raise notice 'Failed to gridify geometry';
   raise notice '% %', SQLERRM, SQLSTATE;
   RETURN NEXT geom;
  END;
  $body$
  LANGUAGE 'plpgsql';
