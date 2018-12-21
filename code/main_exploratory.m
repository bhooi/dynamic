close all; clear all; clc;
cd ~/Desktop/bryan-papers/power/dynamic/code
addpath ~/Desktop/bryan-papers/gridanom/code/matpower6.0
addpath util
addpath detection
addpath detection/var
addpath wprctile/

rng(0);

case_name = 'case2383wp';
nclust_choices = 5:5:20;
num_choices = length(nclust_choices);

M_in = loadcase(case_name);

base_Lr = M_in.bus(:,3);
base_Li = M_in.bus(:,4);
variation_level = 0;
noise_level = .2;

num_periods = 100;
period = 30; % 1 period = 5 minutes, 1 data point = 5 secs
num_ticks = num_periods * period;

graph_changes = 1;
num_anom = 50;

use_cached_evaldata = false;
save_results = true;

M_in = renumber_matpower_nodes(M_in);
E = M_in.branch(:,1:2)';
G = grid2graph(M_in);

num_nodes = size(M_in.bus, 1);
num_edges = size(M_in.branch, 1);
Ir = zeros(num_ticks,num_edges);
Ii = zeros(num_ticks,num_edges);
Vr = zeros(num_ticks,num_nodes);
Vi = zeros(num_ticks,num_nodes);

anom_time = sort(randsample(1:num_ticks, num_anom));
all_attempts = cell(1, num_ticks);

%%


exploratory_file = sprintf('../output/exploratory_%s_%.2f_%.2f.mat', case_name, variation_level, noise_level);

if use_cached_evaldata
    load(exploratory_file);
else
    graph_del_edges = {};
    [Lr, Li] = generate_load('LBNL', base_Lr, base_Li, num_ticks, variation_level, noise_level);
    for t = 1:num_ticks
        fprintf('t=%d\n',t);
        while true % keep generating until we get a success
            if t == 1
                cur_graph_del = [];
            elseif mod(t, period) == 1
                cur_graph_del = randsample(1:num_edges, 1);
            end
            cur_attempt = cur_graph_del;
            [Ir(t,:), Ii(t,:), Vr(t,:), Vi(t,:), success] = simulate_matpower(M_in, Lr(t,:), Li(t,:), cur_attempt);
            if success
                all_attempts{t} = cur_attempt;
                if mod(t, period) == 1
                    graph_del_edges = [graph_del_edges cur_graph_del];
                end
                break
            end
        end
    end
    save(exploratory_file, 'Ir','Ii','Vr','Vi', 'graph_del_edges');
end

%%

Im = sqrt(Ir.^2 + Ii.^2);
Imean = mean(Im(1:60,:), 1);

M = M_in;
n = size(M.bus, 1);
m = size(M.branch, 1);
L = sparse(M.branch(:,1), M.branch(:,2), 1 ./ (1e-3 + M.branch(:,3)), n, n);
L = L + L';
L = diag(sum(L)) - L;

num_periods = length(graph_del_edges);
R = cell(1, num_periods);
for i=1:num_periods
    e = graph_del_edges{i};
    Lsub = sparse(M.branch(e,1), M.branch(e,2), 1 ./ (1e-3 + M.branch(e,3)), n, n);
    Lsub = Lsub + Lsub';
    Lsub = diag(sum(Lsub)) - Lsub;
    
    Lcur = L - Lsub;
    [U,D,V] = svds(Lcur);
    Gcur = V * diag(1./diag(D)) * U';
    R{i} = ones(n,1) * diag(Gcur)' + diag(Gcur) * ones(n,1)' - 2 * Gcur;
end

%%

%%

X = compute_features(M_in, Ir, Ii, Vr, Vi);

Xd = X(:, 2:end,:) - X(:, 1:end-1, :);
Xp = permute(Xd, [2 1 3]);
Xp = bsxfun(@minus, Xp, median(Xp, 1));
Xz = bsxfun(@rdivide, Xp, iqr(Xp, 1)+1e-6);

incidence_mat = abs(get_incidence_matrix(M_in));

%%
Xsensors = nan(num_ticks-1, 6*n);
for sensor_idx = 1:n
    sensor_edges = incidence_mat(:, sensor_idx);
    Xi = Xz(:,:,sensor_edges == 1);
    
    Xedge = max(abs(Xi), [], 3); % single edge anomaly
    Xave = mean(Xi, 3); % group anomaly
    Xdev = std(Xi, [], 3); % group diversion anomaly
    
    Xsensors(:, 6*(sensor_idx-1) + (1:2)) = Xedge;
    Xsensors(:, 6*(sensor_idx-1) + (3:4)) = Xave;
    Xsensors(:, 6*(sensor_idx-1) + (5:6)) = Xdev;
end
%%
Zmed = nan(num_periods, size(Xsensors, 2));

Xcur = Xsensors(1:period-1,:);
Xmed0 = median(Xcur, 1);
Xiqr0 = iqr(Xcur, 1)+1e-6;

for i=1:num_periods
    idx = i*period + (1:period-1);
    Xmed = median(Xsensors(idx,:), 1);
    Zmed(i,:) = abs((Xmed - Xmed0) ./ Xiqr0);
end
%%
for i=1:num_periods
    Zmax(i) = max(Zmed(i,:));
    Zmean(i) = mean(Zmed(i,:));
end
%%
graph_dist = zeros(num_periods, 1);
for i=1:num_periods
    err = R{1} - R{i};
    e = graph_del_edges{i};
%     graph_dist(i) = norm(sqrt(err), 'fro');
%     graph_dist(i) = norm(err, 'fro');
%     graph_dist(i) = norm(err, 1);
%     graph_dist(i) = max(abs(err(:)));
%     graph_dist(i) = Imean(e);
%     graph_dist(i) = M_in.branch(e, 3);
end
%%

% [~, gd_ord] = sort(graph_dist);
% [~, Zm_ord] = sort(Zmean);

k = 1;
mdl = fitlm((graph_dist).^k, Zmean);
mdl
% plot(mdl);
figure; plot((graph_dist).^k, Zmean, 'x'); xlabel('Graph distance'); ylabel('Sensor difference');
