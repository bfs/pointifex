# Pointifex

Postgis functions so ummm... pointy and metric, make you wanna slap yo pope (and Neal Stephenson). 

## 


### pointify_geom(geometry,size_in_meters)

Reduces a geometry to a set of points comprising a simplified perimeter and interior points every "size_in_meters".


Example:
```sql
-- return a set of points
select pointify_geom(the_geom,20) from some_table;


-- generate a geojson
select st_asgeojson(st_collect(g)) from (select pointify_geom(the_geom,20) as g from some_table where id=123) t;

```


### gridify_geom(geometry,size_in_meters)

Chops up a geometry into "size_in_meters" squares, returning a set of geometries contained within the boundaries.

Example:
```sql

-- return a set of 20m square geometries (or intersecting subset) inside the_geom 
select pointify_geom(the_geom,20) from some_table;


-- generate a geojson
select st_asgeojson(st_collect(g)) from (select gridify_geom(geometry,20) as g from 
some_table where id=123) t;

```


### st_buffer_meters(geometry,size_in_meters)

Projects your geometry to one that's friendly to meters (vs radians, furlongs, cubits, etc.), buffers, and then projects back.

Example:

```sql
-- produce a geometry with a 20 meter buffer
select st_buffer_meters(the_geom,20) from some_table;

```


### st_segmentize_meters(geometry,size_in_meters)

Projects your geometry to one that's friendly to meters, segmentizes, and then projects back.

Example:

```sql
-- segmentize a geometry with a 20 meter maximum segment length
select st_segmentize_meters(the_geom,20) from some_table;

```

depends on (included) utmzone.sql