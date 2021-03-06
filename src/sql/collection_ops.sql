-- # -- # -- # -- # -- #
-- Collection-level operations
-- # -- # -- # -- # -- #


/* Create a collection with the specified name.
 * Example:
 *   select bq_create_collection('orders');
 */
CREATE OR REPLACE FUNCTION bq_create_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN
IF NOT (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('
    CREATE TABLE IF NOT EXISTS %1$I (
        _id varchar(256) PRIMARY KEY NOT NULL,
        bq_jdoc jsonb NOT NULL,
        created timestamptz default current_timestamp,
        updated timestamptz default current_timestamp,
        CONSTRAINT validate_id CHECK ((bq_jdoc->>''_id'') IS NOT NULL)
    );
    CREATE INDEX idx_%1$I_bq_jdoc ON %1$I USING gin (bq_jdoc);
    CREATE UNIQUE INDEX idx_%1$I_bq_jdoc_id ON %1$I ((bq_jdoc->>''_id''));
    ', quote_ident(i_coll));
    RETURN true;
ELSE
    RETURN false;
END IF;
END
$$ LANGUAGE plpgsql;


/* Get a list of existing collections.
 * This checks information_schema for tables matching the expected structure.
 * Example:
 *   select bq_list_collections();
 */
CREATE OR REPLACE FUNCTION bq_list_collections()
RETURNS table(collection_name text) AS $$
BEGIN
RETURN QUERY SELECT table_name::text
       FROM information_schema.columns
       WHERE column_name = 'bq_jdoc'
       AND data_type = 'jsonb';
END
$$ LANGUAGE plpgsql;


/* Delete/drop a collection.
 * At the moment, this just drops whatever table matches the collection name.
 * Example:
 *   select bq_delete_collection('orders');
 */
CREATE OR REPLACE FUNCTION bq_delete_collection(i_coll text)
RETURNS BOOLEAN AS $$
BEGIN
IF (SELECT bq_collection_exists(i_coll))
THEN
    EXECUTE format('DROP TABLE %I CASCADE;', quote_ident(i_coll));
    RETURN true;
ELSE
    RETURN false;
END IF;
END
$$ LANGUAGE plpgsql;


/* Check if a collection exists.
 * Example:
 *   select bq_collection_exists('orders');
 */
CREATE OR REPLACE FUNCTION bq_collection_exists (i_coll text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT table_name FROM information_schema.columns
    where table_name = i_coll and column_name = 'bq_jdoc'
  );
END
$$ LANGUAGE plpgsql;
