function plot_graph_edge_color(M, G, branch_data, edge, show_labels, colmax)
figure('Position', [0 0 500 500]);
redColorMap = [ones(1, 128), linspace(1, 0, 128)];
greenColorMap = [linspace(0, 1, 128), linspace(1, 0, 128)];
blueColorMap = [linspace(0, 1, 128), ones(1, 128)];
colorMap = .95 * [redColorMap; greenColorMap; blueColorMap]';

for i=1:size(M.branch, 1)
    e = double(G.Edges.EndNodes(i,:));
    found = ismember(M.branch(:,1:2), e, 'rows') + ismember(M.branch(:,1:2), fliplr(e), 'rows');
    edge_data(i) = branch_data(found == 1);
end

if show_labels
    myplot = plot(G, 'NodeColor', 'k', 'MarkerSize', 3, 'Layout', 'force', 'LineWidth', 4, 'EdgeLabel', round(edge_data, 3));
    E = M.branch(:,1:2);
    if ~isempty(edge)
        highlight(myplot, E(edge, 1), E(edge, 2), 'LineWidth', 15);
    end
else
    mylabel = cell(1, G.numnodes);
    mylabel(:) = {' '};
    myplot = plot(G, 'NodeColor', 'k', 'MarkerSize', 3, 'Layout', 'force', 'LineWidth', 4, 'NodeLabel', mylabel);
end
xlim([min(myplot.XData)-.1 max(myplot.XData)+.1]);
ylim([min(myplot.YData)-.1 max(myplot.YData)+.1]);
myplot.EdgeCData = edge_data;
colormap(colorMap);
if show_labels
    mybar = colorbar;
end
if isempty(colmax)
    colmax = max(abs(branch_data));
end
set(gca, 'CLim', [-colmax colmax]);
set(findall(gcf,'Type','Text'),'FontSize',20);
set(gca,'XTick',[]); set(gca,'YTick',[]);
set(gca,'XTickLabel',{' '}); set(gca,'YTickLabel',{' '});
box off; axis off;

