
function [Lr, Li] = generate_load(data_name, base_Lr, base_Li, num_ticks, variation_level, noise_level)
CMU_PQ = csvread(sprintf('../data/%s_PQ.csv', data_name));
CMU_PQ = CMU_PQ(1:num_ticks, :);
PQ_ratio = nan(size(CMU_PQ));
for i=1:2
    X = CMU_PQ(:,i) / CMU_PQ(1,i);
    mu = mean(X);
    sigma = std(X);
    X = smooth(X,.05);
    X = mu + variation_level * (X - mu);
    PQ_ratio(:,i) = X + normrnd(0, noise_level * sigma, num_ticks, 1);
end
num_loads = size(base_Lr, 1);
Lr = zeros(num_ticks,num_loads);
Li = zeros(num_ticks,num_loads);
for i = 1:num_loads
    Lr(:,i) = base_Lr(i) * max(0, PQ_ratio(:,1));
    Li(:,i) = base_Li(i) * max(0, PQ_ratio(:,2));
end
end