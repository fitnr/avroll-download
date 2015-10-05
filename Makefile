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

FY_2016 = avroll_16
FY_2015 = avroll_15
FY_2014 = avroll_14
FY_2013 = avroll_13
FY_2012 = avroll_12
FY_2011 = avroll_11
FY_2010 = all_10

BASE = http://www1.nyc.gov/assets/finance/downloads/tar
YEAR = $(FY_2016)

AVROLL = $(BASE)/$(YEAR).zip

DB = mysql
DATABASE = avroll

PASSFLAG = -p

MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS) $(MYSQLFLAGS)
SQLITE = sqlite3 $(SQLITEFLAGS)

IMPORTFLAGS = FIELDS TERMINATED BY ',' \
	OPTIONALLY ENCLOSED BY '\"' \
	LINES TERMINATED BY '\n' \
	IGNORE 1 LINES

.PHONY: all mysql sqlite check-%

all: $(YEAR).csv

sqlite: $(DATABASE).db

$(DATABASE).db: schema-sqlite.sql description.csv $(YEAR).csv
	$(SQLITE) $@ < $<
	$(SQLITE) $@ "CREATE INDEX IF NOT EXISTS bble ON $(YEAR) (BBLE);"

	tail -n+2 description.csv | $(SQLITE) $@ -separator ',' ".import /dev/stdin description"

	tail -n+2 $(lastword $^) | $(SQLITE) $@ -separator ',' '.import /dev/stdin $(YEAR)'

mysql: schema-mysql.sql description.csv $(YEAR).csv
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE);"
	$(MYSQL) $(DATABASE) --execute="DROP TABLE IF EXISTS $(YEAR); DROP TABLE IF EXISTS description;"

	$(MYSQL) $(DATABASE) < $<
	$(MYSQL) $(DATABASE) --execute "ALTER TABLE $(YEAR) ADD INDEX BBLE (BBLE);"

	$(MYSQL) $(DATABASE) --local-infile --execute="LOAD DATA LOCAL INFILE 'description.csv' INTO TABLE description \
	$(IMPORTFLAGS);"

	$(MYSQL) $(DATABASE) --local-infile --execute="LOAD DATA LOCAL INFILE '$(lastword $<)' INTO TABLE $(YEAR) \
	$(IMPORTFLAGS);"

description.csv: $(YEAR).mdb
	mdb-export $(EXPORTFLAGS) $< 'Condensed Roll Description' > $@

# Escape silly trailing slashes in the data set
$(YEAR).csv: $(YEAR).mdb
	mdb-export $(EXPORTFLAGS) $< avroll | \
	sed -e 's/\\/\\\\/g' > $@

schema-sqlite.sql schema-mysql.sql: schema-%.sql: $(YEAR).mdb
	mdb-schema $< $* | \
	sed -e 's/\(CREATE TABLE\) .avroll./\1 $(YEAR)/g' | \
	sed -e 's/Condensed Roll Description/description/g' > $@

$(YEAR).mdb: $(YEAR).zip; unzip -p $< '*.mdb' > $@

.INTERMEDIATE: $(YEAR).zip
$(YEAR).zip: ; curl --location --progress-bar --output $@ $(AVROLL)

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
