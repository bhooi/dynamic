function [Ihat] = fit_R(method, period)

cmd = sprintf('/usr/local/bin/R CMD BATCH "--args %d" %s.R ../temp/%s.out', period, method, method);
system(cmd);
Ihat = dlmread('../temp/R_out.txt')';
delete ../temp/*.txt