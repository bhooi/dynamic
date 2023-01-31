% solve for level nu such that SUM_i max(0, nu - d_i) = 1

function nu = solve_level(dists)

sdist = sort(dists);
for i=1:length(dists)
    psum = sum(sdist(1:i));
    nu = (1 + psum) / i;
    if nu < sdist(i+1)
        disp(i)
        disp(nu)
        break
    end
end
weights = max(0, nu - dists);