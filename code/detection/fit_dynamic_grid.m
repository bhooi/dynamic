% X is a (num_edge_features = 2) x (num_scenarios) x (num_edges) matrix which is
% output from compute_features

function scores = fit_dynamic_grid(X, cur_sensors, graph_dist, incidence_mat)

num_ticks = size(X, 2);
n = size(incidence_mat, 2);

Xd = X(:, 2:end,:) - X(:, 1:end-1, :);
Xp = permute(Xd, [2 1 3]);
Xp = bsxfun(@minus, Xp, median(Xp, 1));
Xz = bsxfun(@rdivide, Xp, iqr(Xp, 1)+1e-6);

Xsensors = nan(num_ticks-1, 6*length(cur_sensors));
for sensor_idx = 1:length(cur_sensors)
    sensor_node = cur_sensors(sensor_idx);
    sensor_edges = incidence_mat(:, sensor_node);
    Xi = Xz(:,:,sensor_edges == 1);
    
    Xedge = max(abs(Xi), [], 3); % single edge anomaly
    Xave = mean(Xi, 3); % group anomaly
    Xdev = std(Xi, [], 3); % group diversion anomaly

    Xsensors(:, 6*(sensor_idx-1) + (1:2)) = Xedge;
    Xsensors(:, 6*(sensor_idx-1) + (3:4)) = Xave;
    Xsensors(:, 6*(sensor_idx-1) + (5:6)) = Xdev;
end

num_periods = size(graph_dist, 1);
period = num_ticks / num_periods;

tick_dist = kron(graph_dist, ones(period));
tick_dist = tick_dist(2:end, 2:end);

anom_scores = nan(size(Xsensors));
for t=1:num_ticks-1
    weights = compute_dist_weights(tick_dist(t, 1:t));
%     cur_center = weights * Xsensors(1:t, :);
%     cur_scale = sqrt(weights * ((Xsensors(1:t, :) - ones(t,1) * cur_center).^2));
    stats = wprctile(Xsensors(1:t, :), [25 50 75], weights);
    cur_center = stats(2,:);
    cur_scale = stats(3,:) - stats(1,:);
    anom_scores(t,:) = abs(Xsensors(t,:) - cur_center) ./ (cur_scale + 1e-6);
end
scores0 = max(anom_scores, [], 2);
scores = [-inf; min(scores0(1:end-1), scores0(2:end)); -inf];

end