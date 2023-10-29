% INPUT: dists is the tick distances of the current point to all previous
% ticks
% OUTPUT: weights is the weights we assign to previous ticks. These weights
% sum up to 1 and smaller tick distances lead to higher weights.

% To do this, letting the distances be d_i,
% we first solve for level nu such that SUM_i max(0, nu - d_i) = 1
% Then the weight assigned to point i is max(0, nu - d_i)
% Note that these values sum to 1, and high dists d_i lead to setting their
% weight to 0, so such ticks have 0 effect on our final estimates

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
