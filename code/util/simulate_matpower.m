% Lr and Li are real and imaginary loads (vectors of length = no. of nodes)
% cur_del is which edge to delete (or pass empty vector [] for no deletion)
function [Ir, Ii, Vr, Vi, success] = simulate_matpower(M, Lr, Li, cur_del)
define_constants;
M.bus(:,VMAX) = max(M.bus(:,VMAX), 1.2);
M.bus(:,VMIN) = max(M.bus(:,VMIN), 0.8);
if ~isempty(Lr)
    M.bus(:, PD) = Lr;
    M.bus(:, QD) = Li;
end
if ~isempty(cur_del)
    M.branch(cur_del, BR_STATUS) = 0; % delete one power line
end
% if length(find_islands(M)) > 1
%     fprintf('DISCONNECTED\n');
%     Ir = 0; Ii = 0; Vr = 0; Vi = 0; success = 0;
% else
out = runpf(M, mpoption('verbose', 0, 'out.all', 0));
success = out.success;

Vr = out.bus(:,VM) .* cos(pi / 180 * out.bus(:,VA));
Vi = out.bus(:,VM) .* sin(pi / 180 * out.bus(:,VA));
V = Vr + 1i * Vi;
impedance = M.branch(:,BR_R) + 1i * M.branch(:, BR_X);
I = (V(M.branch(:, 1)) - V(M.branch(:, 2))) ./ impedance;
I(cur_del) = 0;
Ir = real(I); 
Ii = imag(I);
% end


end