function A = read_graph(data_name)
filenames = dir(sprintf('../data/%s/out.*', data_name));
file_id = fopen(sprintf('../data/%s/%s', data_name, filenames.name));
E = textscan(file_id, '%f %f %f %f', 'CommentStyle' , '%');
max_idx = max([E{1}; E{2}]);
A = sparse(E{1}, E{2}, 1, max_idx, max_idx);
A = A + A';
end