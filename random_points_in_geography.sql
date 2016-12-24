CREATE OR REPLACE FUNCTION random_points_in (
  geog geography,
  number_of_points int
  )
RETURNS setof geography AS
$body$
  DECLARE

  envelope geometry;

  res geometry;

  Xmin double precision;
  Xmax double precision;
  Ymin double precision;
  Ymax double precision;
 
  randX double precision;
  randY double precision;

  point_count int = 0;

  BEGIN

    WHILE point_count < number_of_points LOOP
       
        envelope := ST_Envelope(geog::geometry);
        Xmin := ST_XMin(envelope);
        Xmax := ST_XMax(envelope);
        Ymax := ST_YMax(envelope);
        Ymin := ST_YMin(envelope);

        randX := (random() * (Xmax - Xmin)) + Xmin;
        randY := (random() * (Ymax - Ymin)) + Ymin;

        res := ST_SetSRID(ST_Point(randX, randY), 4326)::geography;

        IF ST_Intersects(res,geog) THEN
          point_count := point_count + 1;
          RETURN NEXT res; 
        END IF;

    END LOOP;
  END; 
  $body$
  LANGUAGE 'plpgsql';
