# Gnuplot script file for plotting data in file "force.dat"
# This file is called   force.p
set   autoscale                        # scale axes automatically
unset log                              # remove any log-scaling
unset label                            # remove any previous labels
set xtic auto                          # set xtics automatically
set ytic auto                          # set ytics automatically
set y2tics
set title "perf usage : ".runname
set xlabel "time (ms)"
set ylabel "RAM (ko)"
set origin 0,0;
set datafile separator ","
set term png size 1200,1200
set output runname.".ram.png"

plot runname.".log.csv" u 1:2  w l title columnheader(2), \
""                      u 1:3  w l title columnheader(3), \
""                      u 1:4  w l title columnheader(4), \
""                      u 1:5  w l title columnheader(5), \
""                      u 1:6  w l title columnheader(6);
set output runname.".cpu.png"
set xlabel "time (ms)"
set ylabel "CPU (%)"
set yrange [0:100]
set origin 0,0;
plot runname.".log.csv" u 1:7  w l title columnheader(7), \
""                      u 1:8  w l title columnheader(8), \
""                      u 1:9  w l title columnheader(9), \
""                      u 1:10  w l title columnheader(10), \
""                      u 1:11 w l title columnheader(11);