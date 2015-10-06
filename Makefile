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

FY_2016_TC1 = tc1_16
FY_2016_TC2 = tc234_16
FY_2016_condensed = avroll_16

FY_2015_TC1 = tc1_15
FY_2015_TC2 = tc234_15
FY_2015_condensed = avroll_15

FY_2014_TC1 = tc1_14
FY_2014_TC2 = tc234_14
FY_2014_condensed = avroll_14

FY_2013_TC1 = tc1_13
FY_2013_TC2 = tc234_13
FY_2013_condensed = avroll_13

FY_2012_TC1 = tc1_12
FY_2012_TC2 = tc234_12
FY_2012_condensed = avroll_12

FY_2011_TC1 = tc1_11
FY_2011_TC2 = tc234_11
FY_2011_condensed = avroll_11

FY_2010_TC1 = tc1_10
FY_2010_TC2 = tc234_10
FY_2010_condensed = all_10

FY_2009_TC1 = tc1
FY_2009_TC2 = tc234

BASE = http://www1.nyc.gov/assets/finance/downloads/tar
YEAR = FY_2016

DB = mysql
DATABASE = avroll

PASSFLAG = -p

MYSQL = mysql
MYSQLOGIN = --user "$(USER)" $(PASSFLAG)$(PASS)

PSQL = psql
PSQLOGIN = --username "$(USER)"

SQLITE = sqlite3

IMPORTFLAGS = FIELDS TERMINATED BY ',' \
	OPTIONALLY ENCLOSED BY '\"' \
	LINES TERMINATED BY '\n'

.PHONY: all mysql mysql-% postgresql postgresql-% sqlite sqlite-% check-% complete condensed

all: complete condensed

complete: $(YEAR).csv
	@echo *** downloaded $(YEAR).csv

condensed: $(YEAR)_condensed.csv
	@echo *** downloaded $(YEAR)_condensed.csv

#
# SQLite
#
sqlite: sqlite-complete sqlite-condensed

sqlite-condensed: sqlite-description-load sqlite-condensed-load

sqlite-complete: sqlite-TC1 sqlite-TC2

sqlite-TC1 sqlite-TC2: sqlite-%: $(YEAR)_%.csv | $(DATABASE).db
	$(SQLITE) $(SQLITEFLAGS) $| -separator , ".import $< $(YEAR)"

sqlite-description-load sqlite-condensed-load: sqlite-%-load: $(YEAR)_%.csv | $(DATABASE).db
	$(SQLITE) $(SQLITEFLAGS) $| -separator , ".import $< $(YEAR)_$*"

$(DATABASE).db: sqlite_$(YEAR)_tc.sql sqlite_$(YEAR)_condensed.sql
	$(SQLITE) $(SQLITEFLAGS) $@ < $<
	$(SQLITE) $(SQLITEFLAGS) $@ "CREATE INDEX IF NOT EXISTS bble ON $(YEAR) (BBLE);"

	$(SQLITE) $(SQLITEFLAGS) $@ < $(lastword $^)
	$(SQLITE) $(SQLITEFLAGS) $@ "CREATE INDEX IF NOT EXISTS bblec ON $(YEAR)_condensed (BBLE);"

#
# PostgreSQL
#
postgresql: posgresql-complete posgresql-condensed

posgresql-complete: posgresql-$(YEAR)-TC1 posgresql-$(YEAR)-TC2

posgresql-condensed: posgresql-$(YEAR)-condensed

posgresql-$(YEAR)-TC1 posgresql-$(YEAR)-TC2: posgresql-$(YEAR)-%: $(YEAR)_%.csv | posgresql-$(YEAR)-tc-load
	$(PSQL) $(PSQLOGIN) --dbname $(DATABASE) $(PSQLFLAGS) --command "COPY $(YEAR) FROM '$(abspath $<)' DELIMITER ',' CSV QUOTE '\"';"

posgresql-$(YEAR)-condensed: $(YEAR)_description.csv $(YEAR)_condensed.csv | posgresql-$(YEAR)-condensed-load
	$(PSQL) $(PSQLOGIN) --dbname $(DATABASE) $(PSQLFLAGS) --command "COPY $(YEAR)_description FROM '$(abspath $<)' DELIMITER ',' CSV QUOTE '\"';"
	$(PSQL) $(PSQLOGIN) --dbname $(DATABASE) $(PSQLFLAGS) --command "COPY $(YEAR)_condensed FROM '$(abspath $<)' DELIMITER ',' CSV QUOTE '\"';"

posgresql-$(YEAR)-tc-load posgresql-$(YEAR)-condensed-load: posgresql-$(YEAR)-%-load: mysql_$(YEAR)_%.sql | posgresql-create
	$(PSQL) $(PSQLOGIN) --dbname $(DATABASE) $(PSQLFLAGS) < $<

posgresql-create:
	$(PSQL) $(PSQLOGIN) $(PSQLFLAGS) --execute="CREATE DATABASE $(DATABASE);"  || echo $(DATABASE) probably exists

#
# MySQL
#
mysql: mysql-complete mysql-condensed

mysql-complete: mysql-$(YEAR)-TC1 mysql-$(YEAR)-TC2
	$(MYSQL) $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) --execute "ALTER TABLE $(YEAR) ADD INDEX BBLE (BBLE);"

mysql-condensed: mysql-$(YEAR)-condensed
	$(MYSQL) $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) --execute "ALTER TABLE $(YEAR)_condensed ADD INDEX BBLE (BBLE);"

mysql-$(YEAR)-TC1 mysql-$(YEAR)-TC2: mysql-$(YEAR)-%: $(YEAR)_%.csv | mysql-$(YEAR)-tc-load
	$(MYSQL) $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) --local-infile --execute "LOAD DATA LOCAL INFILE '$<' INTO TABLE $(YEAR) \
	$(IMPORTFLAGS);"

mysql-$(YEAR)-condensed: $(YEAR)_description.csv $(YEAR)_condensed.csv | mysql-$(YEAR)-condensed-load
	$(MYSQL) $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) --local-infile --execute "LOAD DATA LOCAL INFILE '$<' INTO TABLE $(YEAR)_description \
	$(IMPORTFLAGS);"

	$(MYSQL) $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) --local-infile --execute "LOAD DATA LOCAL INFILE '$(lastword $^)' INTO TABLE $(YEAR)_condensed \
	$(IMPORTFLAGS);"

mysql-$(YEAR)-condensed-load mysql-$(YEAR)-tc-load: mysql-$(YEAR)-%-load: mysql_$(YEAR)_%.sql | mysql-create
	$(MYSQL) $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) < $<

mysql-create:
	$(MYSQL) $(MYSQLOGIN) $(MYSQLFLAGS) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE);"

#
# CSV
#
$(YEAR).csv: $(YEAR)_TC2.mdb $(YEAR)_TC2.csv $(YEAR)_TC1.csv
	mdb-export $< tc234 | head -n1 > $@
	cat $(filter-out $<,$^) >> $@

$(YEAR)_TC2.csv: $(YEAR)_TC2.mdb
	mdb-export -H $(EXPORTFLAGS) $< tc234 > $@

$(YEAR)_TC1.csv: $(YEAR)_TC1.mdb
	mdb-export -H $(EXPORTFLAGS) $< tc1 > $@

$(YEAR)_description.csv: $(YEAR)_condensed.mdb
	mdb-export -H $(EXPORTFLAGS) $< 'Condensed Roll Description' > $@

$(YEAR)_condensed.csv: $(YEAR)_condensed.mdb
	mdb-export -H $(EXPORTFLAGS) $< avroll > $@

#
# SQL schemas
#
	mdb-schema -T tc1 -N $(YEAR) $< $* | sed -e 's/_tc1//g' > $@
mysql_$(YEAR)_tc.sql postgres_$(YEAR)_tc.sql sqlite_$(YEAR)_tc.sql: %_$(YEAR)_tc.sql: $(YEAR)_TC1.mdb | schemas

	mdb-schema -N $(YEAR) $< $* | \
mysql_$(YEAR)_condensed.sql postgres_$(YEAR)_condensed.sql sqlite_$(YEAR)_condensed.sql: %_$(YEAR)_condensed.sql: $(YEAR)_condensed.mdb | schemas
	sed -e 's/avroll/condensed/g' | \
	sed -e 's/Condensed Roll Description/description/g' > $@

schemas: ; mkdir -p $@

#
# mdb
#
$(YEAR)_TC1.mdb $(YEAR)_TC2.mdb $(YEAR)_condensed.mdb: $(YEAR)_%.mdb: $(YEAR)_%.zip
	unzip -p $< '*.mdb' > $@

.INTERMEDIATE: $(YEAR)_TC1.zip $(YEAR)_TC2.zip $(YEAR)_condensed.zip

#
# zip
#
$(YEAR)_TC1.zip $(YEAR)_TC2.zip $(YEAR)_condensed.zip: $(YEAR)_%.zip:
	curl --location --progress-bar --output $@ $(BASE)/$($(YEAR)_$*).zip

#
# utilities
#
clean:
	rm -f $(TARGET)
	$(MYSQL) --execute "DROP DATABASE IF EXISTS $(DATABASE);" || :
	rm -f description.csv avroll.{zip,mdb,csv} schema.sql

check-sqlite: $(DATABASE).db
	$(SQLITE) $(SQLITEFLAGS) -echo $< 'select * FROM avroll limit 10'
	$(SQLITE) $(SQLITEFLAGS) -echo $< 'select * FROM description'

check-mysql:
	$(MYSQL) -D $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) -e 'SELECT * FROM avroll LIMIT 10'
	$(MYSQL) -D $(DATABASE) $(MYSQLOGIN) $(MYSQLFLAGS) -e 'SELECT * FROM description'

.PHONY: install
install:
	( \
		which brew && brew install mdbtools \
	) || ( \
		git clone https://github.com/brianb/mdbtools.git && \
		cd mdbtools && \
		sudo apt-get -qq install -y gnome-doc-utils glib2.0-dev && \
		autoreconf -i -f && \
		./configure --disable-man && \
		make && \
		sudo make install && \
		sudo ldconfig \
	)
