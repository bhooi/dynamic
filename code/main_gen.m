close all; clear all; clc;
cd ~/Desktop/bryan-papers/power/dynamic/code
addpath ~/Desktop/bryan-papers/gridanom/code/matpower6.0
addpath util
addpath detection
addpath detection/var

rng(0);

%% GENERATE LOAD PATTERN
case_name = 'case2383wp';

M_in = loadcase(case_name);

base_Lr = M_in.bus(:,3);
base_Li = M_in.bus(:,4);
noise_level = .0;
variation_level = .1;

num_periods = 20;
period = 60; % 1 period = 5 minutes, 1 data point = 5 secs
num_ticks = num_periods * period;

graph_changes = 1;
num_anom = 20;

use_cached_evaldata = true;

M_in = renumber_matpower_nodes(M_in);
E = M_in.branch(:,1:2)';
G = grid2graph(M_in);

num_nodes = size(M_in.bus, 1);
num_edges = size(M_in.branch, 1);
Ir = zeros(num_ticks,num_edges);
Ii = zeros(num_ticks,num_edges);
Vr = zeros(num_ticks,num_nodes);
Vi = zeros(num_ticks,num_nodes);

anom_time = sort(randsample(1:num_ticks, num_anom));
graph_del = nan(1, num_periods);
all_attempts = cell(1, num_ticks);


%%
evaldata_file = sprintf('../output/eval_%s_%.2f_%.2f.mat', case_name, variation_level, noise_level);

if use_cached_evaldata
    load(evaldata_file);
else
    anom_edges = [];
    graph_del_edges = [];
    [Lr, Li] = generate_load('LBNL', base_Lr, base_Li, num_ticks, variation_level, noise_level);
    for t = 1:num_ticks
        fprintf('t=%d\n',t);
        while true % keep generating until we get a success
            if mod(t, period) == 1
                cur_graph_del = randsample(1:num_edges, 1);
            end
            cur_attempt = cur_graph_del;
            if any(t == anom_time)
                cur_anom = randsample(setdiff(1:num_edges, cur_graph_del), 1);
                cur_attempt = [cur_attempt cur_anom];
            end
            [Ir(t,:), Ii(t,:), Vr(t,:), Vi(t,:), success] = simulate_matpower(M_in, Lr(t,:), Li(t,:), cur_attempt);
            if success
                all_attempts{t} = cur_attempt;
                if any(t == anom_time)
                    anom_edges = [anom_edges cur_anom];
                end
                if mod(t, period) == 1
                    graph_del_edges = [graph_del_edges cur_graph_del];
                end
                break
            end
        end
    end
    save(evaldata_file, 'Ir','Ii','Vr','Vi','anom_edges', 'graph_del_edges', 'anom_time', 'all_attempts');
end



%%

% array2table(fmeas, 'VariableNames', method_names, 'RowNames', data_names)
% 
% array2table(mean(fmeas, 1), 'VariableNames', method_names)
% 
% 
% %% BAR GRAPH
% % 
% for data_idx = 1:length(data_names)
%     fprintf('%s:\n', data_names{data_idx});
%     (fmeas(data_idx,1)-fmeas(data_idx,:)) ./ fmeas(data_idx,:)
%     
%     case_name = data_names{data_idx};
%     figure('Position', [0 0 500 500]); hold on;
%     for i=1:num_methods
%         bar(i, fmeas(data_idx, i), 'FaceColor', cols(i,:));
%     end
%     ylabel('F-measure');
%     set(gca, 'XTick', 1:num_methods, 'XTickLabels', method_names);
%     set(gca,'XTickLabelRotation',90)
%     ylim([0 1]); xlim([.5 inf]);
%     set(gca,'YTick', [0:1]);
%     set(gcf, 'PaperPositionMode', 'auto');
%     set(findall(gcf,'Type','Axes'),'FontSize',20);
%     set(findall(gcf,'Type','Text'),'FontSize',24);
%     set(findall(gcf,'Type','Legend'),'FontSize',20);
%     printpdf(gcf, sprintf('../plots/err_%s.pdf', case_name));
%     hold off;
% end