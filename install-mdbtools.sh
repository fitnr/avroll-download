git clone https://github.com/brianb/mdbtools.git
yum install --qq -y glib2.0-dev
cd mdbtools
autoreconf -i -f
./configure
make
sudo make install
