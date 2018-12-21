function sensors_random = selection_random(M_in, nclust_choices)

sensors_random = cell(1, length(nclust_choices));
num_nodes = size(M_in.bus, 1);
cur_sensors = [];
for i = 1:length(nclust_choices)
    num_to_add = nclust_choices(i) - length(cur_sensors);
    added_sensors = randsample(num_nodes, num_to_add);
    cur_sensors = [cur_sensors; added_sensors];
    sensors_random{i} = cur_sensors;
end