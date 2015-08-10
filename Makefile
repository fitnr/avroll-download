ZIP = https://data.cityofnewyork.us/download/rgy2-tti8/application/zip
DATABASE = avroll
PASS = 

.PHONY: mysql
mysql: schema.sql avroll.csv description.csv
	mysql --user="$(USER)" -p$(PASS) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE)"

	mysql --user="$(USER)" -p$(PASS) --database="$(DATABASE)" \
	--execute "DROP TABLE IF EXISTS avroll; DROP TABLE IF EXISTS Description;"

	mysql --user="$(USER)" -p$(PASS) --database="$(DATABASE)" < $<

	mysql --user="$(USER)" -p$(PASS) --database="$(DATABASE)" \
	--execute="LOAD DATA LOCAL INFILE '$(word 2,$^)' INTO TABLE $(DATABASE).avroll \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES"

	mysql --user="$(USER)" -p$(PASS) --database="$(DATABASE)" \
	--execute="LOAD DATA LOCAL INFILE '$(word 3,$^)' INTO TABLE $(DATABASE).Description \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES"

description.csv: AVROLL.mdb
	mdb-export $< 'Condensed Roll Description' > $@

avroll.csv: AVROLL.mdb
	mdb-export $< avroll | \
	sed -e 's/\\/\\\\/g' > $@

schema.sql: AVROLL.mdb
	mdb-schema $< mysql | \
	sed 's/Condensed Roll Description/Description/g' > $@

AVROLL.mdb: AVROLL.zip
	unzip $< $@
	@touch $@

.INTERMEDIATE: AVROLL.zip
AVROLL.zip: ; curl $(ZIP) > $@

clean: ; mysql --user="$(USER)" -p$(PASS) --execute "DROP DATABASE IF EXISTS $(DATABASE);"

.PHONY: install
install: ; brew install mdbtools
