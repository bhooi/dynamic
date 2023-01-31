function graph_dist = compute_LODF_dist(M, graph_del_edges, varargin)
    
num_periods = length(graph_del_edges);
n = size(M.bus, 1);
m = size(M.branch, 1);

Branch=M.branch;

% K = makePTDF(M); 
% LODF = makeLODF(Branch, K);
% LODF_alt=LODF-diag(diag(LODF));
[~,LODF_alt] = compute_LODF(M,graph_del_edges);
importance=nan(num_periods, 1);

for i=1:num_periods
    %e = graph_del_edges{i};
    %LODF_target=(LODF_alt(:,e));
    LODF_target=(LODF_alt(:,i));
    importance(i)=sum(mean(abs(LODF_target)));    
end

graph_dist = zeros(num_periods, num_periods);
for i=1:num_periods
    for j=i+1:num_periods
        graph_dist(i, j) = importance(i) + importance(j); 
    end
end
graph_dist = graph_dist + graph_dist';
end