% X is a (num_edge_features = 2) x (num_scenarios) x (num_edges) matrix which is
% output from compute_features

function scores = fit_dynamic_delta(Xsensors, graph_dist)

num_ticks = size(Xsensors, 1);
num_sensors = size(Xsensors, 2);
num_periods = size(graph_dist, 1);
period = num_ticks / num_periods;

tick_dist = kron(graph_dist, ones(period));
tick_dist = tick_dist(2:end, 2:end);

Xd = Xsensors(2:end,:) - Xsensors(1:end-1, :);

anom_scores = nan(size(Xd));
for t=1:num_ticks-1
    weights = compute_dist_weights(tick_dist(t, 1:t));
%     cur_mean = weights * Xd(1:t, :);
%     cur_sd = sqrt(t / (t-1) * weights * ((Xd(1:t, :) - ones(t,1) * cur_mean).^2));
    stats = wprctile(Xd(1:t, :), [25 50 75], weights);
    cur_mean = stats(2,:);
    cur_sd = stats(3,:) - stats(1,:);
    anom_scores(t,:) = abs(Xd(t,:) - cur_mean) ./ (cur_sd + 1e-3);
end
scores0 = max(anom_scores, [], 2);
scores = [-inf; min(scores0(1:end-1), scores0(2:end)); -inf];

end