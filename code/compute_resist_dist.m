function graph_dist = compute_resist_dist(M, graph_del_edges)

n = size(M.bus, 1);
m = size(M.branch, 1);
L = sparse(M.branch(:,1), M.branch(:,2), 1 ./ (1e-3 + M.branch(:,3)), n, n);
L = L + L';
L = diag(sum(L)) - L; % Lapacian of original graph

num_periods = length(graph_del_edges);
R = cell(1, num_periods); % R{i} is the effective resistance matrix of the ith graph
for i=1:num_periods
    e = graph_del_edges{i};
    Lsub = sparse(M.branch(e,1), M.branch(e,2), 1 ./ (1e-3 + M.branch(e,3)), n, n);
    Lsub = Lsub + Lsub';
    Lsub = diag(sum(Lsub)) - Lsub;
    
    Lcur = L - Lsub; % Laplacian of the modified current graph
    [U,D,V] = svds(Lcur);
    Gcur = V * diag(1./diag(D)) * U';
    
    R{i} = ones(n,1) * diag(Gcur)' + diag(Gcur) * ones(n,1)' - 2 * Gcur; % formula for effective resistance
end

graph_dist = zeros(num_periods, num_periods);
for i=1:num_periods
    for j=i+1:num_periods
        graph_dist(i, j) = norm((R{i} - R{j}), 1); % graph distance is the L1 distance between the 2 effective resistance matrices
    end
end
graph_dist = graph_dist + graph_dist';
end