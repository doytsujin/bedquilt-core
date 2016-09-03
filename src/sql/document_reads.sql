-- # -- # -- # -- # -- #
-- Document Reads
-- # -- # -- # -- # -- #


/* find one
 */
CREATE OR REPLACE FUNCTION bq_find_one(i_coll text, i_json_query jsonb, i_skip integer DEFAULT 0, i_sort jsonb DEFAULT null)
RETURNS table(bq_jdoc jsonb) AS $$
DECLARE
  q text;
  mq text;
  sq text[];
  s text;
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    -- base query
    q := format('SELECT bq_jdoc::jsonb FROM %I', quote_ident(i_coll));
    -- split json query doc into match query and special queries
    SELECT match_query, special_queries
      FROM bq_util_split_queries(i_json_query::jsonb)
      INTO mq, sq;
    q := q || format(' WHERE bq_jdoc @> (%s)::jsonb ', quote_literal(mq));
    IF array_length(sq, 1) > 0
    THEN
      FOREACH s IN ARRAY sq
      LOOP
        q := q || format(' AND %s ', s);
      END LOOP;
    END IF;
    -- sort
    IF (i_sort IS NOT NULL)
    THEN
      q := q || format(' %s ', bq_util_sort_to_text(i_sort));
    END IF;
    -- skip
    q := q || format(' offset %s ', i_skip);
    -- final query
    q := q || ' limit 1 ';
    RETURN QUERY EXECUTE q;
  END IF;
END
$$ LANGUAGE plpgsql;


-- find one by id
CREATE OR REPLACE FUNCTION bq_find_one_by_id(i_coll text, i_id text)
RETURNS table(bq_jdoc jsonb) AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
  THEN
    RETURN QUERY EXECUTE format(
      'SELECT bq_jdoc::jsonb FROM %I
      WHERE _id = %s
      LIMIT 1',
      quote_ident(i_coll),
      quote_literal(i_id)
    );
  END IF;
END
$$ LANGUAGE plpgsql;

-- find many by ids
CREATE OR REPLACE FUNCTION bq_find_many_by_ids(i_coll text, i_ids jsonb)
RETURNS table(bq_jdoc jsonb) AS $$
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    IF jsonb_typeof(i_ids) != 'array'
    THEN
      RAISE EXCEPTION
      'Invalid ids parameter "%s"', jsonb_typeof(i_ids)
      USING HINT = 'ids should be a json array of strings';
    END IF;
    RETURN QUERY EXECUTE format(
      'SELECT bq_jdoc::jsonb FROM %I
      WHERE _id = ANY(array(select jsonb_array_elements_text(%s::jsonb)))
      ORDER BY created ASC;',
      quote_ident(i_coll),
      quote_literal(i_ids)
    );
  END IF;
END
$$ LANGUAGE plpgsql;


/* find many documents
 */
CREATE OR REPLACE FUNCTION bq_find(i_coll text, i_json_query jsonb, i_skip integer DEFAULT 0, i_limit integer DEFAULT null, i_sort jsonb DEFAULT null)
RETURNS table(bq_jdoc jsonb) AS $$
DECLARE
  q text = format('select bq_jdoc::jsonb from %I ', quote_ident(i_coll));
  mq text;
  sq text[];
  s text;
BEGIN
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    IF jsonb_typeof(i_sort) != 'array'
    THEN
      RAISE EXCEPTION
      'Invalid sort parameter json type "%s"', jsonb_typeof(i_sort)
      USING HINT = 'The i_sort parameter to bq_find should be a json array';
    END IF;
    -- query match
    SELECT match_query, special_queries
      FROM bq_util_split_queries(i_json_query::jsonb)
      INTO mq, sq;
    q := q || format(' WHERE bq_jdoc @> (%s)::jsonb ', quote_literal(mq));
    -- special queries
    IF array_length(sq, 1) > 0
    THEN
      FOREACH s IN ARRAY sq
      LOOP
        q := q || format(' AND %s ', s);
      END LOOP;
    END IF;
    -- sort
    IF (i_sort IS NOT NULL)
    THEN
      q := q || bq_util_sort_to_text(i_sort);
    END IF;
    -- skip and limit
    IF (i_limit IS NOT NULL)
    THEN
      q := q || format(' LIMIT %s::integer ', quote_literal(i_limit));
    END IF;
    q := q || format(' offset %s::integer ', quote_literal(i_skip));
    -- final query
    RETURN QUERY EXECUTE q;
  END IF;
END
$$ LANGUAGE plpgsql;


/* count documents in collection
 */
CREATE OR REPLACE FUNCTION bq_count(i_coll text, i_doc jsonb)
RETURNS integer AS $$
DECLARE
  o_value int;
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
  EXECUTE format(
    'SELECT COUNT(_id) from %I
    WHERE bq_jdoc @> (%s)::jsonb',
     quote_ident(i_coll),
     quote_literal(i_doc)
  ) INTO o_value;
  RETURN o_value;
ELSE
  return 0;
END IF;
END
$$ LANGUAGE plpgsql;


/* Get a sequence of the distinct values present in the collection for a given key,
 * example: bq_distinct('people', 'address.city')
 */
CREATE OR REPLACE FUNCTION bq_distinct(i_coll text, i_key_path text)
RETURNS table(val jsonb) AS $$
DECLARE
  path_array text[];
BEGIN
  path_array := regexp_split_to_array(i_key_path, '\.');
  IF (SELECT bq_collection_exists(i_coll))
  THEN
    RETURN QUERY EXECUTE format(
      'select distinct (bq_jdoc#>%s)::jsonb as val from %I',
      quote_literal(path_array), quote_ident(i_coll)
    );
  END IF;
END
$$ LANGUAGE plpgsql;
