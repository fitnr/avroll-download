Assessed Value Roll downloader
==============================

This Makefile downloads NYC assessed value data and loads it into MySQL.

The NYC Department of Finance makes assessed value data available as a Microsoft Access database. If you're comfortable working with Access, you should [download that file](https://data.cityofnewyork.us/download/rgy2-tti8/application/zip).

## Requirements

* [mdbtools](https://github.com/brianb/mdbtools)
* MySQL

## Installation

Download this repository and open the folder in your terminal.

You'll have to install [mysql](http://www.mysql.com/downloads/) yourself.

Next, you'll need to install mdbtools. If you're on OS X with Homebrew installed run:
````
$ make install
````

If not, install [mdbtools](https://github.com/brianb/mdbtools) some other way.

## Downloading the data

Check that you have mysql up and running on your machine, and a user capable of creating databases. Don't use root!

Run the following command:
````
$ make USER=myuser PASS=mypass
````

(If you don't want to type your password in plaintext, you can leave off the PASS argument. You'll just have to enter the password several times.)

This will run the following tasks:
* download the AVROLL mdb as a zip file.
* Convert it to CSV
* generate schemas for a new MySQL table
* Create a new MySQL database (`avroll`) and import the data a new avroll table
* Add an index to the avroll table

### Using an existing database

If you want to add the data to tables in an existing database, run:
````
$ make DATABASE=mydb USER=myuser PASS=mypass
````

If you're using a remote database, something like this will work:
````
$ make DATABASE=mydb USER=myuser PASS=mypass MYSQLFLAGS='--host=example.com --port=123'
````

## License

[General Public License version 3](https://www.gnu.org/licenses/gpl.html)
