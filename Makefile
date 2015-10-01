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
PASSFLAG = -p
MYSQL = mysql --user="$(USER)" $(PASSFLAG)$(PASS) $(MYSQLFLAGS)

.PHONY: all mysql description.mysql avroll.mysql

all: description avroll

description avroll: %: %.csv | mysql
	$(MYSQL) --execute="LOCK TABLES $(DATABASE).$* WRITE; \
	LOAD DATA LOCAL INFILE '$<' INTO TABLE $(DATABASE).$* \
	FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES; \
	UNLOCK TABLES;"

mysql: schema.sql
	$(MYSQL) --execute="CREATE DATABASE IF NOT EXISTS $(DATABASE); \
	DROP TABLE IF EXISTS $(DATABASE).avroll; \
	DROP TABLE IF EXISTS $(DATABASE).description;"

	$(MYSQL) --database $(DATABASE) < $<
	$(MYSQL) --execute "ALTER TABLE $(DATABASE).avroll ADD INDEX BBLE (BBLE);"

description.csv: AVROLL.mdb
	mdb-export $< 'Condensed Roll Description' > $@

# Escape silly trailing slashes in the data set
avroll.csv: AVROLL.mdb
	mdb-export $< avroll | \
	sed -e 's/\\/\\\\/g' > $@

schema.sql: AVROLL.mdb
	mdb-schema $< mysql | \
	sed 's/Condensed Roll Description/description/g' > $@

AVROLL.mdb: AVROLL.zip
	unzip -o $< $@
	@touch $@

.INTERMEDIATE: AVROLL.zip
AVROLL.zip: ; curl --location --silent --output $@ $(AVROLL)

clean: ; $(MYSQL) --execute "DROP DATABASE IF EXISTS $(DATABASE);"

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
