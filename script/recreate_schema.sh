#!/bin/bash

# Remove the backup schema.
rm -f lib/PAPS/Model/DB.pm.prev
# Rename the current schema to act as a backup.
mv lib/PAPS/Model/DB.pm lib/PAPS/Model/DB.pm.prev

# Create the new schema.
script/paps_create.pl model DB DBIC::Schema PAPS::Schema create=static naming=v4 components=TimeStamp,EncodedColumn 'dbi:Pg:dbname=papsdb' 'papsuser' '' '{ AutoCommit => 1 }'
