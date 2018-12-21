function graph_dist = compute_current_dist(M, graph_del_edges)
    
num_periods = length(graph_del_edges);
n = size(M.bus, 1);
m = size(M.branch, 1);
conduct = nan(n, 1);

for i=1:num_periods
    e = graph_del_edges{i};
    conduct(i) = 1./ (1e-6 + M.branch(e,3));
end

graph_dist = zeros(num_periods, num_periods);
for i=1:num_periods
    for j=i+1:num_periods
        graph_dist(i, j) = conduct(i) + conduct(j);
    end
end
graph_dist = graph_dist + graph_dist';
end