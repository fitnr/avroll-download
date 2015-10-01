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

all: avroll.csv

sqlite: $(DATABASE).db

$(DATABASE).db: schema-sqlite.sql description.csv avroll.csv
	$(SQLITE) $@ < $<
	$(SQLITE) $@ "CREATE INDEX IF NOT EXISTS bble ON avroll (BBLE);"

	tail -n+2 description.csv | $(SQLITE) $@ -separator , ".import /dev/stdin description"

	tail -n+2 $(lastword $^) | $(SQLITE) $@ -separator , '.import /dev/stdin avroll'


mysql: schema-mysql.sql description.csv avroll.csv
	$(MYSQL) --execute "DROP DATABASE IF EXISTS $(DATABASE);"
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE);"
	$(MYSQL) $(DATABASE) --execute="DROP TABLE IF EXISTS avroll; DROP TABLE IF EXISTS description;"

	$(MYSQL) $(DATABASE) < $<
	$(MYSQL) $(DATABASE) --execute "ALTER TABLE avroll ADD INDEX BBLE (BBLE);"

	$(MYSQL) $(DATABASE) --local-infile --execute="LOAD DATA LOCAL INFILE 'description.csv' INTO TABLE description \
	$(IMPORTFLAGS);"

	$(MYSQL) $(DATABASE) --local-infile --execute="LOAD DATA LOCAL INFILE 'avroll.csv' INTO TABLE avroll \
	$(IMPORTFLAGS);"

description.csv: AVROLL.mdb
	mdb-export $(EXPORTFLAGS) $< 'Condensed Roll Description' > $@

# Escape silly trailing slashes in the data set
avroll.csv: AVROLL.mdb
	mdb-export $(EXPORTFLAGS) $< avroll | \
	sed -e 's/\\/\\\\/g' > $@

schema-sqlite.sql schema-mysql.sql: schema-%.sql: AVROLL.mdb
	mdb-schema $< $* | sed 's/Condensed Roll Description/description/g' > $@

AVROLL.mdb: AVROLL.zip
	unzip -o $< $@
	@touch $@

.INTERMEDIATE: AVROLL.zip
AVROLL.zip: ; curl --location --silent --output $@ $(AVROLL)

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
