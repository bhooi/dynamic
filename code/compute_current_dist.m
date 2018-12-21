function graph_dist = compute_current_dist(M, graph_del_edges)
    
num_periods = length(graph_del_edges);
n = size(M.bus, 1);
m = size(M.branch, 1);
conduct = nan(num_periods, 1);

for i=1:num_periods
    e = graph_del_edges{i};
    % conduct(i) is the conductance (i.e. 1/resistance) of edge deleted in the ith step
    conduct(i) = 1./ (1e-6 + M.branch(e,3)); 
end

graph_dist = zeros(num_periods, num_periods);
for i=1:num_periods
    for j=i+1:num_periods
        % graph distance is just the sum of the 2 conductances of the 2
        % deleted edges
        graph_dist(i, j) = conduct(i) + conduct(j); 
    end
end
graph_dist = graph_dist + graph_dist';
end