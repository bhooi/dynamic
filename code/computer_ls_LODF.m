function graph_dist = computer_ls_LODF(M, graph_del_edges, cur_sensors, varargin)

num_periods = length(graph_del_edges);
nb = size(M.bus, 1);
nl = size(M.branch, 1);

[LODF,LODF_alt] = compute_LODF(M,graph_del_edges);
importance=nan(num_periods, 1);
ls_filter=cell(num_periods,1);

f=M.branch(:,1); %from bus list
t=M.branch(:,2); %to bus list
Cft =  sparse([f; t], [1:nl 1:nl]', [ones(nl, 1); ones(nl, 1)], nb, nl);%incidence matrix with ones
sensor_branch=Cft(cur_sensors,:)';%num branch * num sensors
num_sensors = length(cur_sensors);

for i=1:num_periods
     LODF_target=(LODF_alt(:,i));
     LODF_target_raw=(LODF(:,i));

    importance(i)=mean(abs(LODF_target))';
    sensor_filter=zeros(num_sensors,1);
    for k=1:num_sensors
        sensor_filter(k,:)=max(abs(LODF_target_raw.*(sensor_branch(:,k))));
    end
    ls_filter{i}=sensor_filter; %the distance between deleted line and each sensor
end

graph_dist = zeros(num_periods, num_periods, num_sensors);
for i=1:num_periods
    for j=i+1:num_periods
        graph_dist(i, j, :) = ls_filter{i}*importance(i)+ls_filter{j}*importance(j);
    end
end
for k=1:num_sensors
graph_dist(:, :, k)=graph_dist(:, :, k) + graph_dist(:, :, k)';
end

end
