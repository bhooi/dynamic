% X is a (num_edge_features = 2) x (num_scenarios) x (num_edges) matrix which is
% output from compute_features

function scores = fit_dynamic(Xsensors, graph_dist)

num_ticks = size(Xsensors, 1);
num_periods = size(graph_dist, 1);
period = num_ticks / num_periods;

tick_dist = kron(graph_dist, ones(period));

anom_scores = nan(size(Xsensors));
for t=1:num_ticks
    weights = compute_dist_weights(tick_dist(t, 1:t));
    cur_mean = weights * Xsensors(1:t, :);
    cur_sd = sqrt(weights * ((Xsensors(1:t, :) - ones(t,1) * cur_mean).^2));
%     stats = wprctile(Xsensors(1:t, :), [25 50 75], weights);
%     cur_mean = stats(2,:);
%     cur_sd = stats(3,:) - stats(1,:);
    anom_scores(t,:) = abs(Xsensors(t,:) - cur_mean) ./ (cur_sd + 1e-10);
end
scores = max(anom_scores, [], 2);

end