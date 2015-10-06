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

MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS) $(MYSQLFLAGS)
SQLITE = sqlite3 $(SQLITEFLAGS)

IMPORTFLAGS = FIELDS TERMINATED BY ',' \
	OPTIONALLY ENCLOSED BY '\"' \
	LINES TERMINATED BY '\n' \
	IGNORE 1 LINES

.PHONY: all mysql mysql-% sqlite sqlite-% check-% complete condensed 

all: $(YEAR).csv $(YEAR)_condensed.csv

sqlite: sqlite-TC1 sqlite-TC2 sqlite-description sqlite-condensed | $(DATABASE).db

sqlite-TC1 sqlite-TC2: sqlite-%: $(YEAR)_%.csv | $(DATABASE).db
	tail -n+2 $< | $(SQLITE) $| -separator ',' ".import /dev/stdin $(YEAR)_$*"

sqlite-description sqlite-condensed: sqlite-%: $(YEAR)_%.csv | $(DATABASE).db
	tail -n+2 $< | $(SQLITE) $| -separator ',' ".import /dev/stdin $(YEAR)_$*"

$(DATABASE).db: schemas/sqlite_$(YEAR).sql schemas/sqlite_$(YEAR)_condensed.sql
	$(SQLITE) $@ < $<
	$(SQLITE) $@ "CREATE INDEX IF NOT EXISTS bble ON $(YEAR) (BBLE);"

	$(SQLITE) $@ < $(lastword $^)
	$(SQLITE) $@ "CREATE INDEX IF NOT EXISTS bble ON $(YEAR)_condensed (BBLE);"

complete: mysql-$(YEAR)-TC1 mysql-$(YEAR)-TC2

condensed: mysql-$(YEAR)-condensed

mysql: mysql-$(YEAR)-TC1 mysql-$(YEAR)-TC2 mysql-$(YEAR)-condensed

mysql-$(YEAR)-TC1 mysql-$(YEAR)-TC2: mysql-$(YEAR)-%: $(YEAR)_%.csv | mysql-$(YEAR)
	$(MYSQL) $(DATABASE) --local-infile --execute="LOAD DATA LOCAL INFILE '$<' INTO TABLE $(YEAR) \
	$(IMPORTFLAGS);"

mysql-$(YEAR)-condensed: $(YEAR)_description.csv $(YEAR)_condensed.csv
	$(MYSQL) $(DATABASE) --local-infile --execute="LOAD DATA LOCAL INFILE '$<' INTO TABLE $(YEAR)_description \
	$(IMPORTFLAGS);"

	$(MYSQL) $(DATABASE) --local-infile --execute="LOAD DATA LOCAL INFILE '$(lastword %^)' INTO TABLE $(YEAR)_condensed \
	$(IMPORTFLAGS);"

mysql-$(YEAR): schemas/mysql_$(YEAR).sql | mysql-create
	$(MYSQL) $(DATABASE) < $<
	$(MYSQL) $(DATABASE) --execute "ALTER TABLE $(YEAR) ADD INDEX BBLE (BBLE);"

mysql-$(YEAR)-condensed-load: schemas/mysql_$(YEAR)_condensed.sql | mysql-create
	$(MYSQL) $(DATABASE) < $<
	$(MYSQL) $(DATABASE) --execute "ALTER TABLE $(YEAR)_condensed ADD INDEX BBLE (BBLE);"

mysql-create:
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE);"

$(YEAR).csv: $(YEAR)_TC2.csv $(YEAR)_TC1.csv
	head -n1 $< > $@ 
	{ $(foreach file,$^,tail -n+2 $(file) ;) } >> $@

$(YEAR)_TC2.csv: $(YEAR)_TC2.mdb
	mdb-export $(EXPORTFLAGS) $< tc234 > $@

$(YEAR)_TC1.csv: $(YEAR)_TC1.mdb
	mdb-export $(EXPORTFLAGS) $< tc1 > $@

$(YEAR)_description.csv: $(YEAR)_condensed.mdb
	mdb-export $(EXPORTFLAGS) $< 'Condensed Roll Description' > $@

$(YEAR)_condensed.csv: $(YEAR)_condensed.mdb
	mdb-export $(EXPORTFLAGS) $< avroll > $@

schemas/mysql_$(YEAR).sql schemas/sqlite_$(YEAR).sql: schemas/%_$(YEAR).sql: $(YEAR)_TC1.mdb | schemas
	mdb-schema -T tc1 $< $* | sed -e 's/.tc1./$(YEAR)/g' > $@

schemas/mysql_$(YEAR)_condensed.sql schemas/sqlite_$(YEAR)_condensed.sql: schemas/%_$(YEAR)_condensed.sql: $(YEAR)_condensed.mdb | schemas
	mdb-schema $< $* | \
	sed -e 's/avroll/$(YEAR)_condensed/g' | \
	sed -e 's/Condensed Roll Description/description/g' > $@

schemas: ; mkdir -p $@

$(YEAR)_TC1.mdb $(YEAR)_TC2.mdb $(YEAR)_condensed.mdb: $(YEAR)_%.mdb: $(YEAR)_%.zip
	unzip -p $< '*.mdb' > $@

.INTERMEDIATE: $(YEAR)_TC1.zip $(YEAR)_TC2.zip $(YEAR)_condensed.zip

$(YEAR)_TC1.zip $(YEAR)_TC2.zip $(YEAR)_condensed.zip: $(YEAR)_%.zip:
	curl --location --progress-bar --output $@ $(BASE)/$($(YEAR)_$*).zip

clean:
	rm -f $(TARGET)
	$(MYSQL) --execute "DROP DATABASE IF EXISTS $(DATABASE);" || :
	rm -f description.csv avroll.{zip,mdb,csv} schema.sql

check-sqlite: $(DATABASE).db
	$(SQLITE) $< 'select * FROM avroll limit 10'
	$(SQLITE) $< 'select * FROM description'

check-mysql:
	$(MYSQL) -D $(DATABASE) -e 'SELECT * FROM avroll LIMIT 10'
	$(MYSQL) -D $(DATABASE) -e 'SELECT * FROM description'

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
