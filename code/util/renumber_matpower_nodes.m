function M_out = renumber_matpower_nodes(M_in)
num_nodes = size(M_in.bus, 1);
M_out = M_in;
nodemap = nan(1, max(M_out.bus(:,1))); 
nodemap(M_out.bus(:,1)) = 1:length(M_out.bus(:,1));
M_out.branch(:, 1:2) = nodemap(M_out.branch(:, 1:2));
M_out.bus(:, 1) = 1:num_nodes;
M_out.gen(:, 1) = nodemap(M_out.gen(:, 1));