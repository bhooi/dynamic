% X is a (num_edge_features = 2) x (num_scenarios) x (num_edges) matrix which is
% output from compute_features

function scores = fit_dynamic_local(X, cur_sensors, graph_del_edges, M, incidence_mat)

R = get_effective_resistance(M);
Rn = R / max(R(:));
num_ticks = size(X, 2);
n = size(incidence_mat, 2);
num_periods = length(graph_del_edges);
num_sensors = length(cur_sensors);
period = num_ticks / num_periods;

dist_to_base = nan(num_periods, num_sensors);
for i = 1:num_periods
    e = graph_del_edges{i};
    e_src = M.branch(e,1);
    e_dst = M.branch(e,2);
    conduct(i) = 1 ./ (1e-6 + M.branch(e,3));
    for s = 1:num_sensors
        dist_to_base(i, s) = conduct(i) * (Rn(s, e_src) + Rn(s, e_dst)) / 2;
    end
end


for s = 1:num_sensors
    cur_graph_dist = zeros(num_periods, num_periods);
    for i=1:num_periods
        for j=i+1:num_periods
            cur_graph_dist(i, j) = dist_to_base(i, s) + dist_to_base(j, s);
        end
    end
    cur_tick_dist = kron(cur_graph_dist, ones(period));
    tick_dist{s} = cur_tick_dist(2:end, 2:end);
end

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


anom_scores = nan(size(Xsensors));
for t=1:num_ticks-1
    stats = nan(3, num_sensors);
    for s=1:num_sensors
        weights = compute_dist_weights(tick_dist(t, 1:t));
        stats(:, s) = wprctile(Xsensors(1:t, s), [25 50 75], weights);
    end
    cur_center = stats(2,:);
    cur_scale = stats(3,:) - stats(1,:);
    anom_scores(t,:) = abs(Xsensors(t,:) - cur_center) ./ (cur_scale + 1e-6);
end
scores0 = max(anom_scores, [], 2);
scores = [-inf; min(scores0(1:end-1), scores0(2:end)); -inf];

end