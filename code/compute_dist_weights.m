% solve for level nu such that SUM_i max(0, nu - d_i) = 1

function weights = compute_dist_weights(dists)

sdist = sort(dists);
for i=1:length(dists)
    psum = sum(sdist(1:i));
    nu = (1 - psum) / i;
    if (i == length(dists)) || (nu < sdist(i+1))
        break
    end
end
weights = max(0, nu - dists);