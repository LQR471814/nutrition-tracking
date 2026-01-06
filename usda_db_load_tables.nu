let create_tables = ls tables/*.csv
	| each {|csv|
		let tablepath = $csv.name
		let tablename = $tablepath
			| path basename
			| parse --regex "^(?<name>\\w+)\\.csv$"
			| get name
			| first
		$".import --skip 1 '($tablepath)' ($tablename)"
	}
	| str join "\n"

rm -f usda.db

let t1 = date now

$"
PRAGMA synchronous = OFF;
PRAGMA journal_mode = WAL;
PRAGMA cache_size = 100000;
PRAGMA locking_mode = EXCLUSIVE;
PRAGMA temp_store = MEMORY;

BEGIN;
(open ./usda_schema.sql)
.mode csv
($create_tables)
COMMIT" | sqlite3 usda.db

let t2 = date now

print "Done in:" ($t2 - $t1)

