Assessed Value Roll downloader
==============================

This Makefile downloads NYC assessed value data and loads it into MySQL or SQLite. It does this with the retro 70s power of `make`.

The NYC Department of Finance makes assessed value data available as a Microsoft Access database. If you're comfortable working with Access, you should [download that file](https://data.cityofnewyork.us/download/rgy2-tti8/application/zip).

See also [nycre](https://github.com/fitnr/nycre), a related project for NYC real estate transaction data.

## Requirements

* A Unix-based system (OS X or Linux)
* [mdbtools](https://github.com/brianb/mdbtools)
* MySQL v14+ or SQLite v3.7.15+ (optional)

## Installation

Download this repository and open the folder in your terminal.

Next, you'll need to install mdbtools. If you're on Debian Linux or OS X with Homebrew installed run:
````
$ make install
````

If not, install [mdbtools](https://github.com/brianb/mdbtools) some other way.

## Downloading the data

If you only wish to download the data into csv, run the following command:

````
$ make
````

The assessed value data will be downloaded and saved as a `avroll_16.csv`. The _16 indicates that it's the data for the 2016 fiscal year.

### Older data

Older data, back to fiscal year 2010, is available. Check the file names at the top of `Makefile`, and use them following this pattern:

````
$ make YEAR=avroll_15
$ ...
$ make YEAR=avroll_11
$ make YEAR=all_10
````

Note it mostly follows a pattern. This will generate files named `avroll_15.csv`, etc.

## MySQL
Check that you have mysql up and running on your machine, and a user capable of creating databases. Don't use root!

````
$ make mysql USER=myuser PASS=mypass
````
(If you don't want to type your password in plaintext, you can leave off the PASS argument. You'll just have to enter the password several times.)

This will create a database called `avroll` with two tables, `avroll_16` and `description`, which contains rather timid metadata. Use the YEAR option, mentioned above, to load data into tables named in the pattern above:
````
$ make mysql YEAR=avroll_15
````

You can change your user settings even a remote database by adding options. Here's an excessive example:

````
$ make mysql USER=myuser PASS=mypass DATABASE=mydb MYSQLFLAGS="-H myhost.com -P 5432"
````

If your mysql user doesn't require a password, set the PASSFLAG option to be blank:
````
$ make mysql USER=myuser PASSFLAG=
````

## SQLite

````
$ make sqlite
````

This will create an SQLite file called `avroll.db` with a table named `avroll_16`. Use the YEAR option to add data from earlier years:
````
$ make sqlite YEAR=avroll_13
````

## License

[General Public License version 3](https://www.gnu.org/licenses/gpl.html)

