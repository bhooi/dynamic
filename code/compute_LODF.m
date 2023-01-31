function [LODF,LODF_alt] = compute_LODF(M,graph_del_edges)
%% a modified version of LODF calculation for only a few observed lines
% in local sensitive graph distance calculation
%LODF has -1 on outageline itself; LODF_alt has 0 on outageline itself
%LODF is a nbranch by nbranch matrix, which tells the LODF(observed branch,deleted branch)
%compute_LODF(branch, size(mpc.bus,1), 1);
branch = M.branch;
nbus = size(M.bus,1);
ntl=size(branch,1);

noref   = (2:nbus)';      %% use bus 1 for voltage angle reference
slack_id = find(M.bus(:, 2) == 3);
slack_id = slack_id(1);
noslack = find((1:nbus)' ~= slack_id); %%idx of not slack bus

from = branch(:, 1);         %% from bus list
to = branch(:, 2);          %% to bus list

deledgesid = [graph_del_edges{:}];
n_deledges = length(deledgesid);
from_deledges = branch(deledgesid,1);
to_deledges = branch(deledgesid,2);
bus_targetid = intersect([from_deledges;to_deledges],noslack);
n_targetbus = length(bus_targetid);

%incidence matrix A
A = sparse([(1:ntl)';(1:ntl)'], [from;to], [ones(ntl, 1); -ones(ntl, 1)], ntl, nbus);    %% connection matrix
A_deledges = sparse([(1:n_deledges)';(1:n_deledges)'],[from_deledges;to_deledges],[ones(n_deledges, 1); -ones(n_deledges, 1)],n_deledges, nbus);

b = 1./branch(:,4); %susceptance vector (b value of each branch)
tap = ones(ntl, 1);                              %% default tap ratio = 1
i = find(branch(:, 9));                       %% indices of non-zero tap ratios
tap(i) = branch(i, 9);                        %% assign non-zero tap ratios
b = b ./ tap;

B_tl = sparse([(1:ntl)';(1:ntl)'], [from; to], [b; -b], ntl, nbus);   %B matrix of branch, nbranch by nbus
B_bus = A'*B_tl;

% %whole matrix
% H1 = zeros(ntl, nbus);
% H1(:, noslack) = full(B_tl(:, noref) / (B_bus(noslack, noref)));
% PTDF1 = H1*A';
% LODF1 = PTDF1 ./ (ones(ntl, ntl) - ones(ntl, 1) * diag(PTDF1)') ;
% LODF1 = LODF1 - diag(diag(LODF1)) - eye(ntl,ntl);
% LODF_cmp = LODF1(:,deledgesid);

%only what we need!
H = zeros(ntl, nbus);
Eye = sparse(1:nbus,1:nbus,ones(1,nbus),nbus,nbus);
H(:,bus_targetid) = B_tl(:, noref)* (B_bus(noslack, noref)\Eye(noslack,bus_targetid));
PTDF = H * A_deledges';
LODF = PTDF ./ (ones(ntl, n_deledges) - ones(ntl, 1) * diag(PTDF(deledgesid,:))');
LODF(deledgesid,:) = LODF(deledgesid,:) - diag(diag(LODF(deledgesid,:)));
LODF_alt = LODF;
LODF(deledgesid,:) = LODF(deledgesid,:) - eye(n_deledges,n_deledges);
% matpower:
% K = makePTDF(mpc); 
% LODF_ref = makeLODF(branch, K);
%% haha = full( Bf(:, noref)* (Bbus(noslack, noref)\sparse(1:100,1:100,ones(1,100),nb-1,100)));

end

