-- Document Reads


-- find one
CREATE OR REPLACE FUNCTION bq_findone_document(
    i_coll text,
    i_json_query json
) RETURNS table(jdoc json) AS $$
BEGIN

IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT jdoc::json FROM %I
        WHERE jdoc @> (''%s'')::jsonb
        LIMIT 1',
        i_coll,
        i_json_query
    );
END IF;

END
$$ LANGUAGE plpgsql;


-- find many documents
CREATE OR REPLACE FUNCTION bq_find_documents(
    i_coll text,
    i_json_query json
) RETURNS table(jdoc json) AS $$
BEGIN

IF (SELECT bq_collection_exists(i_coll))
THEN
    RETURN QUERY EXECUTE format(
        'SELECT jdoc::json FROM %I
        WHERE jdoc @> (''%s'')::jsonb',
        i_coll,
        i_json_query
    );
END IF;

END
$$ LANGUAGE plpgsql;