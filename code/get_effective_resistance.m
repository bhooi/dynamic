function R = get_effective_resistance(M)

n = size(M.bus, 1);
L = sparse(M.branch(:,1), M.branch(:,2), 1 ./ (1e-6 + M.branch(:,3)), n, n);
L = L + L';
L = diag(sum(L)) - L;

[U,D,V] = svds(L);
G = V * diag(1./diag(D)) * U';
R = ones(n,1) * diag(G)' + diag(G) * ones(n,1)' - 2 * G;

    