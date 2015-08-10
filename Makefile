AVROLLZIP = https://data.cityofnewyork.us/download/rgy2-tti8/application/zip

DATABASE = avroll
PASS = 
MYSQL = mysql --user="$(USER)" -p$(PASS) --database="$(DATABASE)"

.PHONY: mysql
mysql: schema.sql avroll.csv description.csv
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE)"

	$(MYSQL) --execute "DROP TABLE IF EXISTS avroll; DROP TABLE IF EXISTS Description;"

	$(MYSQL) < $<

	$(MYSQL) --execute="LOAD DATA LOCAL INFILE '$(word 2,$^)' INTO TABLE $(DATABASE).avroll \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES"

	$(MYSQL) --execute="LOAD DATA LOCAL INFILE '$(word 3,$^)' INTO TABLE $(DATABASE).Description \
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
AVROLL.zip: ; curl $(AVROLLZIP) > $@

clean: ; $(MYSQL) --execute "DROP DATABASE IF EXISTS $(DATABASE);"

.PHONY: install
install: ; brew install mdbtools
