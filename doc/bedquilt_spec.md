# BedquiltDB Spec

## Overview

This document specifies a high-level interface to BedquiltDB.
The examples will be given in a pseudo-python language.


## Connections

- Connect to a PostgreSQL database directly:
`db = bedquilt.BedquiltClient("localhost/bedquilt_test")`
- Get a collection from the database:
`coll = db[‘people’]`


## Database Operations

## Create Collection

Create a collection. Does nothing if the collection already exists.

Params:
- collectionName::String

Returns: Boolean indicating whether the collection was created.

Examples:
```
db.create_collection("people")
```


## Delete Collection

Delete a collection. Does nothing if the collection does not exist.

Params:
- collectionName::String

Returns: Boolean indicating whether the collection was deleted.

Examples:
```
db.delete_collection("people")
```


## List Collections

Get a list of collection names.

Params: None

Returns: List of string names of collections.

Examples:
```
for collection_name in db.list_collections():
    print collection_name
```


## Collection Operations

### Create Index:

Add an index to the collection.  The spec is a json-like map where the
keys are field names and the values are numbers. positive numbers
correspond to ascending index, negative numbers to descending
index. If unique is true, then the index will enforce uniqueness.

Params:
- spec::Map
- unique::Boolean (default False)

Returns: None

Examples:
```
coll.create_index({"name": 1})
```

### Delete Index

Remove an index from the collection.

Params:
- spec::Map

Returns: None

Examples:
```
coll.delete_index({"name": 1})
```

### Add Constraint

Adds a constraint to the fields of this collection.  The spec
describes the fields which should be constrained, and how. This will
validate all existing documents in the collection before
applying. Further writes to this collection will be validated before
writing, and will fail if the written document does not satisfy the
constraints.

Spec Options:
- $required (Boolean) : Enforces that this
  field must be present in all documents
- $notnull (Boolean) : Field must never have a null value
- $type (String) : enforce the type of this field,
  options are "string", "number|double|float",  "array", "object"
- $unique (Boolean) : Enforces uniqueness of this field

Params:
- spec::Map

Returns: Boolean indicating success or failure

Examples:
```
coll.add_constraint({"name": {"$required": True,
                              "$notnull": True,
                              "$type": "string",
                              "$unique": False}})
```


### Insert

Insert a document into the collection. If the document does not
contain an _id field, one will be generated and added to the
document before insertion. If an _id is supplied and there
already exists a document in this collection with the
same _id, that is an error.

Params:
- doc::Map

Returns: String representing the _id field of the document

Examples:
```
_id = coll.insert({"_id": "sarah@example.com",
                   "name": "Sarah Bingham",
                   "age": 42,
                   "likes": ["icecream", "code", "hockey"]})
```


### Save

Write a document to the collection.
If an _id is supplied and there already exists a document in this
collection with the same _id, that document will be
replaced with this one.

If the document does not contain an _id field, one will be
generated and added to the document before insertion as
a new document.

Params:
- doc::Map

Returns: String representing the _id field of the document

Examples:
```
_id = coll.insert({"_id": "sarah@example.com",
                   "name": "Sarah Bingham",
                   "age": 42,
                   "likes": ["icecream", "code", "hockey"]})
sarah_doc = coll.find_one(_id)
sarah_doc[‘likes’].append("music")
coll.save(sarah_doc)
```


### Find One

Retrieve the first document which matches the provided query document
from the collection. The filter specifies the structure of the
returned document.

Params:
- query::Map
- filter::Map (optional)

Returns: A single document, or null if none could be found.

Examples:
```
likes = coll.find_one({"name": "Sarah Bingham"}, {"likes": 1})
```

### Find

Retrieve a sequence of documents which match the provided
query document. The filter specifies the structure of the returned
documents.

Params:
- query::Map
- filter::Map (optional)

Returns: A potentially empty sequence of documents.

Examples:
```
people_who_like_icecream = coll.find(
    {"likes": ["icecream"]}
)
```

### Remove

Remove documents matching the query.

Params:
- query::Map
- multi::Boolean (default False)

Returns: Number, representing the number of documents removed

Examples:
```
removed = coll.remove({"likes": ["pears"]}, multi=True)
```

### Update

Update documents in collection with new data.
The operations map supports the following update operations:
- $set : set fields to values
- $unset : unset, or remove specified fields

Params:
- query::Map
- operations::Map
- multi::Boolean (default False)

Examples:
```
coll.update({"_id": "some_id"},
            {"$set": {"description": "A nice thing"})

coll.update({"likes": ["jazz"]},
            {"$set": {"goodPerson": True}})

coll.update({"likes": ["pineapple"]},
            {"$unset": {"goodPerson": 1}})
```