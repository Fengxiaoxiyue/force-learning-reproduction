function save_force_plots(result, cfg, tag)
%SAVE_FORCE_PLOTS Save training/testing traces and weight diagnostics.

if nargin < 3 || isempty(tag)
    tag = cfg.tag;
end

if ~exist(cfg.figureDir, 'dir')
    mkdir(cfg.figureDir);
end

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 1100, 720]);

subplot(3, 1, 1);
plot(result.simtime, result.ft, 'Color', [0.1, 0.55, 0.1], 'LineWidth', 1.5);
hold on;
plot(result.simtime, result.zt, 'Color', [0.8, 0.1, 0.1], 'LineWidth', 1.2);
hold off;
title('Training: target f(t) and network output z(t)');
xlabel('time (s)');
ylabel('output');
legend({'target', 'network'}, 'Location', 'best');
grid on;

subplot(3, 1, 2);
plot(result.simtime2, result.ft2, 'Color', [0.1, 0.55, 0.1], 'LineWidth', 1.5);
hold on;
plot(result.simtime2, result.zpt, 'Color', [0.8, 0.1, 0.1], 'LineWidth', 1.2);
hold off;
title('Autonomous test after training');
xlabel('time (s)');
ylabel('output');
legend({'target', 'network'}, 'Location', 'best');
grid on;

subplot(3, 1, 3);
plot(result.simtime, result.wo_len, 'Color', [0.1, 0.25, 0.75], 'LineWidth', 1.2);
title('Readout weight norm during training');
xlabel('time (s)');
ylabel('||w||_2');
grid on;

pngPath = fullfile(cfg.figureDir, [tag, '_traces.png']);
pdfPath = fullfile(cfg.figureDir, [tag, '_traces.pdf']);

try
    exportgraphics(fig, pngPath, 'Resolution', 200);
    exportgraphics(fig, pdfPath, 'ContentType', 'vector');
catch
    saveas(fig, pngPath);
    saveas(fig, pdfPath);
end

close(fig);
end
