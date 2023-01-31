function scores = fit_ls_dynamic_grid(X, cur_sensors, graph_dist, incidence_mat)
% INPUT:
% X :  a (num_edge_features = 2) x (num_scenarios) x (num_edges) matrix which is
%      output from compute_features
% cur_sensors: num_sensors*1 vector that gives the indices of the sensors we want
% graph_dist: a num_graph*num_graph*num_sensors tensor that gives distance
%             between the graphs w.r.t. each sensor node
% incidence_mat: the 0/1 adjacency matrix of the original graph
% OUTPUT:
% scores: the vector of anomalousness scores at each time

num_ticks = size(X, 2); 
num_sensors=length(cur_sensors);

Xsensors = nan(num_ticks-1, 6*length(cur_sensors));
for sensor_idx = 1:length(cur_sensors)
    sensor_node = cur_sensors(sensor_idx);
    sensor_edges = incidence_mat(:, sensor_node);
    
    Xd = X(:, 2:end,sensor_edges == 1) - X(:, 1:end-1, sensor_edges == 1); %adjacent differences
    Xp = permute(Xd, [2 1 3]);
    Xp = bsxfun(@minus, Xp, median(Xp, 1));
    Xi = bsxfun(@rdivide, Xp, iqr(Xp, 1)+1e-6); % normalized by median and iqr
    
    Xedge = max(abs(Xi), [], 3); % single edge anomaly
    Xave = mean(Xi, 3); % group anomaly
    Xdev = std(Xi, [], 3); % group diversion anomaly

    Xsensors(:, 6*(sensor_idx-1) + (1:2)) = Xedge; % concatenate detectors
    Xsensors(:, 6*(sensor_idx-1) + (3:4)) = Xave;
    Xsensors(:, 6*(sensor_idx-1) + (5:6)) = Xdev; 
end

num_periods = size(graph_dist, 1);
period = num_ticks / num_periods;

anom_scores = nan(size(Xsensors));

for k=1:num_sensors %k:sensor id
tick_dist = kron(graph_dist(:,:,k), ones(period)); % expand graph distance matrix into tick distance using kronecker multiplication
tick_dist = tick_dist(2:end, 2:end);

    for t=1:num_ticks-1
        weights = compute_dist_weights(tick_dist(t, 1:t));
        stats = wprctile(Xsensors(1:t, 6*(k-1)+1:6*k), [25 50 75], weights); % weighted percentile using tick distances
        cur_center = stats(2,:);
        cur_scale = stats(3,:) - stats(1,:);
        anom_scores(t,6*(k-1)+1:6*k) = abs(Xsensors(t,(6*(k-1)+1):6*k) - cur_center) ./ (cur_scale + 1e-6); % normalize using weighted median and iqr
    end
end

scores0 = max(anom_scores, [], 2); % anomalousness is max anomalousness over sensors
scores = [-inf; min(scores0(1:end-1), scores0(2:end)); -inf]; % pad left and right sides


end

