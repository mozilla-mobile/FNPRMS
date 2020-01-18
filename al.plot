# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
set term png
set output 'al-results.png'
set datafile separator ','
set timefmt "%Y.%m.%d"
set xtics rotate by 45 right
set title "Startup From Applink"
set xlabel "Date"
set format x "%Y/%m/%d"
stats 'al-results.csv' using 2 name "A"
set xdata time
set yrange [A_min-0.1:A_max+0.1]
plot 'al-results.csv' using 1:2 notitle with lines
