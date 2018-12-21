close all; clear all; clc;
cd ~/Desktop/bryan-papers/power/dynamic/code
addpath ~/Desktop/bryan-papers/gridanom/code/matpower6.0
addpath util
addpath detection
addpath detection/var
addpath wprctile/

rng(0);

method_names = {'Proposed', 'GridWatch', 'Isolation', 'VAR', 'LOF', 'Parzen'};
method_switches = [1 1 0 1 1 1]; % convenience switches to turn methods on and off
method_names = method_names(method_switches == 1);
num_methods = length(method_names); 

metric_names = {'AUC', 'FMeasure'};
metric_displaynames = {'AUC', 'F Measure'};

case_name = 'case2383wp';
use_cached_evaldata = true;
nclust_choices = 5:5:20;
num_choices = length(nclust_choices);

M_in = loadcase(case_name);
    
base_Lr = M_in.bus(:,3); % original loads
base_Li = M_in.bus(:,4);
variation_level = .1; % amount of variation over time in loads
noise_level = .2; % noise added to loads

num_periods = 20; % number of time periods
period = 60; % 1 period = 5 minutes, 1 data point = 5 secs
num_ticks = num_periods * period;

graph_changes = 1; % number of edges changing in each period
num_anom = 50;

num_trials = 1;

save_results = true;
plot_anom = false;

M_in = renumber_matpower_nodes(M_in);
E = M_in.branch(:,1:2)';
G = grid2graph(M_in);

num_nodes = size(M_in.bus, 1);
num_edges = size(M_in.branch, 1);
Ir = zeros(num_ticks,num_edges);
Ii = zeros(num_ticks,num_edges);
Vr = zeros(num_ticks,num_nodes);
Vi = zeros(num_ticks,num_nodes);

anom_time = sort(randsample(1:num_ticks, num_anom)); % times when anomalies are added
all_attempts = cell(1, num_ticks);

[cols, markers] = myplotconfig(num_methods);


%%
evaldata_file = sprintf('../output/evaldata_%s_%.2f_%.2f.mat', case_name, variation_level, noise_level);
if use_cached_evaldata % generating data takes a long time so cache it
    load(evaldata_file);
else
    anom_edges = [];
    graph_del_edges = {};
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
true_labels = zeros(1, num_ticks); % zero-one vector with 1s indicating true anomalies
true_labels(anom_time) = 1;

%%
X = compute_features(M_in, Ir, Ii, Vr, Vi); 


%% EVALUATION
incidence_mat = abs(get_incidence_matrix(M_in));

all_scores = cell(num_trials, num_choices, num_methods);
metric_auc = nan(num_trials, num_methods, num_choices);
metric_fmeas = nan(num_trials, num_methods, num_choices);

resist_dist_weight = 800;
current_dist_weight = .002;

gdist_current = compute_current_dist(M_in, graph_del_edges); % graph distance matrix based on current
gdist_current = current_dist_weight * gdist_current / mean(gdist_current(:));

gdist_resist = compute_resist_dist(M_in, graph_del_edges); % graph distance matrix based on effective resistance
gdist_resist = resist_dist_weight * gdist_resist / mean(gdist_resist(:));


%%
for trial_idx=1:num_trials
    fprintf('TRIAL: %d\n', trial_idx);
    sensors_random = selection_random(M_in, nclust_choices);

    for choice_idx = 1:num_choices
        cur_sensors = sensors_random{choice_idx};
        fprintf('%d sensors\n', length(cur_sensors));
        sensors_vec = ismember(1:num_nodes, cur_sensors);
        cur_edgeset = sum(incidence_mat(:, sensors_vec), 2) > 0;
        Xcur = X(:, :, cur_edgeset);
        
        Xperm = permute(Xcur, [2 3 1]); % move scenarios dimension to 1st position
        Xsensors = reshape(Xperm, [size(Xperm, 1) size(Xperm, 2) * size(Xperm, 3)]); % convert to scenarios x features
        Xsensors = [Xsensors Vr(:, cur_sensors) Vi(:, cur_sensors)];

        csvwrite('../temp/Xsensors.csv', Xsensors); % write voltages to file, needed by forest and ets methods
        system('./detection/dist/anomaly_detector/anomaly_detector');

        method_funcs = {
            @() fit_dynamic_grid(X, cur_sensors, gdist_current, incidence_mat),...
            @() fit_gridwatch(X, cur_sensors, incidence_mat),...
            @() [csvread('../temp/forest_out.csv'); nan]',...
            @() fit_var(Xsensors),...
            @() fit_lof(Xsensors),...
            @() fit_parzen(Xsensors)};
        method_funcs = method_funcs(method_switches == 1);

        for method_idx = 1:num_methods
            scores = method_funcs{method_idx}();
            all_scores{choice_idx, method_idx} = scores;
            [sortscores, sortidx] = sort(scores, 'descend');
            topk = ismember(1:length(true_labels), sortidx(1:num_anom));
            [~,~,~,cur_auc] = perfcurve(true_labels, scores, 1);
            metric_auc(trial_idx, method_idx, choice_idx) = cur_auc;
            metric_fmeas(trial_idx, method_idx, choice_idx) = compute_fmeas(true_labels, topk);
        end
    end
end
%%
% if plot_anom
%     for choice_idx = 1:num_choices
%         for method_idx = 1:num_methods
%             figure('Position', [0 0 1200 400]);
%             semilogy(all_scores{choice_idx, method_idx}, '-x'); hold on;
%             ylim([0.1 10^4]); yl = ylim;
%             xlabel('Time'); ylabel('Anom score');
%             for i=anom_time
%                 plot([i i], yl, 'k-');
%             end
%             title(sprintf('%s (%d)', method_names{method_idx}, nclust_choices(choice_idx)));
%             set(findall(gcf,'Type','Axes'),'FontSize',20);
%             set(findall(gcf,'Type','Text'),'FontSize',32);
%             set(findall(gcf,'Type','Legend'),'FontSize',28);
%             printpdf(gcf, sprintf('../plots/anom/anom_%s_%d_%s.pdf', case_name, choice_idx, method_names{method_idx}));
%         end
%     end
% end
%%
mean_auc = reshape(mean(metric_auc, 1), num_methods, num_choices);
mean_fmeas = reshape(mean(metric_fmeas, 1), num_methods, num_choices);
array2table(mean_auc, 'RowNames', method_names)
array2table(mean_fmeas, 'RowNames', method_names)
fprintf('AUC %.4f\n', mean(mean_auc, 2)); fprintf('F %.4f\n', mean(mean_fmeas, 2));
array2table([mean(mean_auc, 2) mean(mean_fmeas, 2) ], 'RowNames', method_names, 'VariableNames', metric_names)
mean_metrics = {mean_auc, mean_fmeas};

%%

savefile = sprintf('../output/main_eval_%s.mat', case_name);
if save_results
    save(savefile, 'mean_metrics');
end
% load(savefile);


%%
for metric_idx = 1:length(mean_metrics)
    for use_legend = 0:1
        figure('Position', [0 0 500 500]);
        for method_idx=1:num_methods
            plot(nclust_choices, mean_metrics{metric_idx}(method_idx,:), '-', 'Marker', markers{method_idx}, 'MarkerSize', 12, 'MarkerFaceColor', cols(method_idx,:), 'Color', cols(method_idx,:), 'LineWidth', 2); hold on;
        end
        xlabel('Number of sensors');
        ylabel(metric_displaynames{metric_idx});
        ylim([0 1]); xlim([0 max(nclust_choices)*1.2]);
        if use_legend == 1
            if metric_idx == 1
                legend(method_names, 'Location', 'southwest');
            else
                legend(method_names, 'Location', 'northwest');
            end
        end
        set(findall(gcf,'Type','Axes'),'FontSize',28);
        set(findall(gcf,'Type','Text'),'FontSize',32);
        set(findall(gcf,'Type','Legend'),'FontSize',24);
        printpdf(gcf, sprintf('../plots/eval_%s_%s_%d.pdf', case_name, metric_names{metric_idx}, use_legend));
    end
end
%%

figure('Position', [0 0 500 500]);
for method_idx=1:num_methods
    plot(nclust_choices, mean_metrics{metric_idx}(method_idx,:), '-', 'Marker', markers{method_idx}, 'MarkerSize', 12, 'MarkerFaceColor', cols(method_idx,:), 'Color', cols(method_idx,:), 'LineWidth', 2); hold on;
end
xlim([-2 -1]); ylim([-2 -1]);
legend(method_names, 'Location', 'southwest');
set(findall(gcf,'Type','Axes'),'FontSize',28);
set(findall(gcf,'Type','Text'),'FontSize',32);
set(findall(gcf,'Type','Legend'),'FontSize',24);
printpdf(gcf, sprintf('../plots/legend_%s_%s.pdf', case_name, metric_names{metric_idx}));