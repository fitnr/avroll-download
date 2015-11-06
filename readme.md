Assessed Value Roll downloader
==============================

This tool downloads NYC assessed value data as CSV and optionally loads it into a database (MySQL, SQLite or PostgreSQL).

The NYC Department of Finance makes assessed value data available as a Microsoft Access databases. If you're comfortable working with Access, [download the data directly from nyc.gov](http://www1.nyc.gov/site/finance/taxes/property-assessment-roll-archives.page).

The most important thing to note is that the data comes in two flavors - complete and condensed. The complete data runs to roughly 120 MB to download, the compressed around 60-100 MB. You can choose to download both or neither

For metadata and background info about this data, [visit the Dept. of Finance](http://www1.nyc.gov/site/finance/taxes/property-assessment-roll-archives.page).

See also [nycre](https://github.com/fitnr/nycre), a related project for NYC real estate transaction data.

## Limitations

The NYC Dept. of Finance apparently stores dates in `VARCHAR` fields, so dates won't be loaded correctly.

## Requirements

* A Unix-based system (OS X or Linux)
* [mdbtools](https://github.com/brianb/mdbtools)
* optional: MySQL v14+ or SQLite v3.7.15+ or PostgreSQL 9.3+

## How it works

Avroll-download uses the awesome power of `[make](https://en.wikipedia.org/wiki/Make_(software))`, a piece of software for building software. `Make` is controlled with a gloried to-do list called a `Makefile`. A `Makefile` has a list of tasks, and can be optionally modified by fiddling with variables. Here's what a basic command `make` looks like:
````
make mytask MYVARIABLE=nyc
````
This tells `make` to do `mytask`, and set `MYVARIABLE` equal to `"nyc"`. Make will then print out a and perform whatever list of commands make up `mytask`. In the case of `avroll-download`, this will entail downloading Access database files, converting them to CSV and optionally loading them into MySQL, SQLite or PostgreSQL.

## Installation

Download or clone this repository and open the folder in your terminal.
````
git clone git@github.com:fitnr/avroll-download.git
cd avroll-download
````

Next, you'll need to install mdbtools. If you're on Debian Linux or OS X with Homebrew installed run:
````
make install
````
If that doesn't work, you can try installing [mdbtools](https://github.com/brianb/mdbtools) manually.

## Downloading the data

If you wish to download both the complete and condensed data into csv files, run the following command:
````
make
````

(It will take some time, as there are large files to download and process!)

The assessed value data will be downloaded and saved as `FY_2016_16.csv` and `FY_2016_16_condensed.csv`.

If you wish to download either "complete" or "condensed" data, but not both, use one of these:
````
make complete
make condensed
````

### Older data

Older data, back to fiscal year 2009, is available. Check the file names at the top of `Makefile`, and use them following this pattern:

````
make YEAR=FY_2010
````

Note that for FY 2009, only complete data is available. Running either of these commands will generate an error:
````
make YEAR=FY_2009
make condensed YEAR=FY_2009
````

Instead, use `make complete YEAR=FY_2009` or `make mysql-complete YEAR=FY_2009`, etc.
````
make YEAR=FY_2015
...
make YEAR=FY_2011
make YEAR=FY_2010
````

Note it mostly follows a pattern. This will generate files named `FY_2015.csv`, etc.

## Databases

Each command below will create a database called `avroll` with `FY_2016`, `FY_2016_condensed` and `FY_2016_description` tables (the last contains rather timid metadata for the condensed table). Use the YEAR option, mentioned above, to load older data. You can also specify to only load the "complete" or "condensed" data.

````
# load FY 2012 data
make mysql YEAR=FY_2012 

# load only complete data
# make sqlite-complete

# load only condensed data for FY 2013
make postgresql-condensed YEAR=FY_2013
````

Read on for details on giving user names and passwords.

### MySQL
To load the data into mysql, run a command in this pattern, where `myuser` and `mypass` are your MySQL username and password:
````
make mysql USER=myuser PASS=mypass
make mysql-complete USER=myuser PASS=mypass
make mysql-condensed USER=myuser PASS=mypass
````

Note that you can add `YEAR=FY_20xx` to any of these commands: `make mysql YEAR=FY_2013`.

If you don't want to type your password in plaintext, you can leave off the PASS argument. You'll have to enter the password several times.

You can change your user settings even a remote database by adding options. Here's an excessive example:
````
make mysql USER=myuser PASS=mypass DATABASE=mydb MYSQLFLAGS="-H myhost.com -P 5432"
````

If you'd like to see what commands that will produce, use the `--dry-run` flag with `make`, which will print, but not execute commands:
````
make -n mysql USER=myuser PASS=mypass DATABASE=mydb MYSQLFLAGS="-H myhost.com -P 5432"
````
Returns:
````
...
mysql mydb --user "myuser" -pmypass -H myhost.com -P 5432 < mysql_FY_2016_tc.sql
...
````

If your mysql user doesn't require a password at all, set the `PASSFLAG` variable to be blank:
````
make mysql USER=myuser PASSFLAG=
````

### Postgres
````
make postgresql USER=username
make postgresql-complete USER=username
make postgresql-condensed USER=username
````
Postgres doesn't allow you to give a password directly. Depending on how your installation is set up, the above will work or will give a no password error. To be prompted for a password, add a `-W` flag:
````
make postgresql USER=username PSQLFLAGS=-W
````

### SQLite

Loading data into an SQLite database doesn't require any user or password information:
````
make sqlite
make sqlite-complete
make sqlite-condensed
````

This will create an SQLite file called `avroll.db`. Use the YEAR option to add data from earlier years:

## License

[General Public License version 3](https://www.gnu.org/licenses/gpl.html)
