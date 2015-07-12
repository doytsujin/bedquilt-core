-- # -- # -- # -- # -- #
-- Utilities
-- # -- # -- # -- # -- #


/* Generate a random string ID.
 * Used by the document write functions to populate the '_id' field
 * if it is missing.
 */
CREATE OR REPLACE FUNCTION bq_generate_id ()
RETURNS char(24) AS $$
BEGIN
RETURN CAST(encode(gen_random_bytes(12), 'hex') as char(24));
END
$$ LANGUAGE plpgsql;


/* private - Set a key in a json document.
 */
CREATE OR REPLACE FUNCTION bq_doc_set_key(i_jdoc json, i_key text, i_val anyelement)
RETURNS json AS $$
BEGIN
RETURN (
  SELECT concat(
      '{',
      string_agg(to_json("key")
        || ':'
        || "value", ','),
      '}'
    )::json
  FROM (SELECT *
  FROM json_each(i_jdoc)
  WHERE key <> i_key
  UNION ALL
  SELECT i_key, to_json(i_val)) as "fields")::json;
END
$$ LANGUAGE plpgsql;


/* Check if a collection exists.
 * Currently does a simple check for a table with the specified name.
 */
CREATE OR REPLACE FUNCTION bq_collection_exists (i_coll text)
RETURNS boolean AS $$
BEGIN
RETURN EXISTS (
    SELECT relname FROM pg_class WHERE relname = format('%s', i_coll)
);
END
$$ LANGUAGE plpgsql;


/* private - Ensure the _id field of the supplied json document
 * is a string value.
 * If it's not, an exception is raised. Ideally, the client should validate
 * this is the case before submitting to the server.
 */
CREATE OR REPLACE FUNCTION bq_check_id_type(i_jdoc json)
RETURNS VOID AS $$
BEGIN
  IF (SELECT json_typeof(i_jdoc->'_id')) <> 'string'
  THEN
    RAISE EXCEPTION 'The _id field is not a string: % ', i_jdoc->'_id'
    USING HINT = 'The _id field must be a string';
  END IF;
END
$$ LANGUAGE plpgsql;


/* private - Check if a dotted path exists in a document
 */
CREATE OR REPLACE FUNCTION bq_path_exists(i_path text, i_jdoc jsonb)
RETURNS boolean AS $$
DECLARE
  path_array text[];
  depth int;
  path_key text;
  current_object jsonb;
BEGIN
  current_object := i_jdoc;
  IF i_path = '' THEN
    RETURN false;
  END IF;
  IF i_path NOT LIKE '%.%' THEN
    RETURN (current_object ? i_path);
  END IF;

  path_array := regexp_split_to_array(i_path, '\.');
  FOREACH path_key IN ARRAY path_array LOOP
    IF jsonb_typeof(current_object) = 'object' THEN
      IF current_object ? path_key THEN
        current_object := current_object->path_key;
      ELSE
        RETURN false;
      END IF;
    ELSIF jsonb_typeof(current_object) = 'array' THEN
      IF path_key ~ '^\d+$' THEN
        current_object := current_object->path_key::int;
      ELSE
        RETURN false;
      END IF;
    ELSE
      RETURN false;
    END IF;
  END LOOP;
  RETURN true;

END
$$ language plpgsql;
