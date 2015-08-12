# AVROLL downloader
# Make tasks for downloading assessed value data from NYC's open data site
# Copyright (C) 2015 Neil Freeman

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

AVROLL = https://data.cityofnewyork.us/download/rgy2-tti8/application/zip

DATABASE = avroll
MYSQL = mysql --user="$(USER)" -p$(PASS) $(MYSQLFLAGS)

.PHONY: mysql
mysql: schema.sql avroll.csv description.csv
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE)"

	$(MYSQL) --execute "DROP TABLE IF EXISTS $(DATABASE).avroll; DROP TABLE IF EXISTS $(DATABASE).Description;"

	$(MYSQL) --database $(DATABASE) < $<

	$(MYSQL) --execute "ALTER TABLE $(DATABASE).avroll ADD INDEX BBLE (BBLE)"

	$(MYSQL) --execute="LOAD DATA LOCAL INFILE '$(word 2,$^)' INTO TABLE $(DATABASE).avroll \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES"

	$(MYSQL) --execute="LOAD DATA LOCAL INFILE '$(word 3,$^)' INTO TABLE $(DATABASE).Description \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES"

description.csv: AVROLL.mdb
	mdb-export $< 'Condensed Roll Description' > $@

# Escape silly trailing slashes in the data set
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
AVROLL.zip: ; curl $(AVROLL) > $@

clean: ; $(MYSQL) --execute "DROP DATABASE IF EXISTS $(DATABASE);"

.PHONY: install
install: ; brew install mdbtools
