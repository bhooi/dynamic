% X is a (num_edge_features = 2) x (num_scenarios) x (num_edges) matrix which is
% output from compute_features

function scores = fit_gridwatch(X, cur_sensors, incidence_mat)

num_ticks = size(X, 2);
n = size(incidence_mat, 2);

Xd = X(:, 2:end,:) - X(:, 1:end-1, :);
Xp = permute(Xd, [2 1 3]);
Xp = bsxfun(@minus, Xp, median(Xp, 1));
Xz = bsxfun(@rdivide, Xp, iqr(Xp, 1)+1e-6);

Xsensors = nan(num_ticks-1, 6*n);
for sensor_idx = 1:length(cur_sensors)
    sensor_node = cur_sensors(sensor_idx);
    sensor_edges = incidence_mat(:, sensor_node);
    Xi = Xz(:,:,sensor_edges == 1);
    
    Xedge = max(abs(Xi), [], 3); % single edge anomaly
    Xave = mean(Xi, 3); % group anomaly
    Xdev = std(Xi, [], 3); % group diversion anomaly
%     Xsensors = [Xsensors Xedge Xave Xdev];
    Xsensors(:, 6*(sensor_idx-1) + (1:2)) = Xedge;
    Xsensors(:, 6*(sensor_idx-1) + (3:4)) = Xave;
    Xsensors(:, 6*(sensor_idx-1) + (5:6)) = Xdev;
end

E = abs(Xsensors');
E = bsxfun(@minus, E, median(E, 2));
Eadj = bsxfun(@rdivide, E, iqr(E, 2)+1e-6);
ET = max(Eadj, [], 1);

scores0 = [ET -inf];
scores = [-inf min(scores0(1:end-1), scores0(2:end))];

end