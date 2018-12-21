% B is an m x n matrix. If edge i is (j,k), then B(i,j) = 1, B(i,k) = -1.
function B = get_incidence_matrix(M)

n = size(M.bus, 1); 
m = size(M.branch, 1);
entries = nan(2*m, 3);
for i=1:m
    e = M.branch(i, 1:2);
    entries(2*(i-1)+1 : 2*i, :) = [i e(1) 1; i e(2) -1];
end
B = sparse(entries(:,1), entries(:,2), entries(:,3), m, n);