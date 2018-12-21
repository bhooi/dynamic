function [cols, markers] = myplotconfig(num_methods)
addpath util/distinguishable_colors
% cols = cbrewer('qual', 'Set1', num_methods);
cols = distinguishable_colors(num_methods);
% cols = lines(num_methods);
% cols = hsv(num_methods);
% cols = parula(num_methods);
% cols = jet(num_methods);

[~, red_idx] = max(cols(:,1) - (cols(:,2) + cols(:,3))/2);
cols([1 red_idx], :) = cols([red_idx 1], :);
cols(1,:) = [1 0 0];
[~, yellow_idx] = max(cols(:,1) + cols(:,2) - cols(:,3));
cols(yellow_idx, :) = max(0, cols(yellow_idx, :) - .1);
markers = {'o','^','square','v','d','p','>', '<', '*', 'h'};