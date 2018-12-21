function G = grid2graph(M_in)

E = M_in.branch;
% nodemap = nan(1, max(M_in.bus(:,1))); 
% nodemap(M_in.bus(:,1)) = 1:length(M_in.bus(:,1));
Esrc = E(:,1);
Edst = E(:,2);
E2 = [Esrc Edst; Edst Esrc]; 
E_uniq = unique(E2, 'rows');
E_ord = E_uniq(E_uniq(:,1) < E_uniq(:,2), :);
G = graph(E_ord(:,1), E_ord(:,2));

end