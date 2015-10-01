Assessed Value Roll downloader
==============================

This Makefile downloads NYC assessed value data and loads it into MySQL or SQLite.

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

The assessed value data will be downloaded and saved as a `avroll.csv`.

## Mysql
Check that you have mysql up and running on your machine, and a user capable of creating databases. Don't use root!

````
$ make mysql USER=myuser PASS=mypass
````
(If you don't want to type your password in plaintext, you can leave off the PASS argument. You'll just have to enter the password several times.)

This will create a database called `avroll` with one table, also called `avroll`. You can change those settings and even use a remote database by adding options, e.g:

````
$ make mysql USER=myuser PASS=mypass DATABASE=myddb MYSQLFLAGS="-H myhost.com -P 5432"
````

If your mysql user doesn't require a password, set the PASSFLAG option to be blank:
````
$ make mysql USER=myuser PASSFLAG=
````

## SQLite

````
# make sqlite
````

This will create an SQLite file called `avroll.db`. To create a file with another name:

## License

[General Public License version 3](https://www.gnu.org/licenses/gpl.html)
