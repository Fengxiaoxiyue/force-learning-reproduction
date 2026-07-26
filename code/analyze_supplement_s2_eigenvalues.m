function result = analyze_supplement_s2_eigenvalues(cfg)
%ANALYZE_SUPPLEMENT_S2_EIGENVALUES Effective spectra for g=0.8 and 1.5.

if nargin < 1 || isempty(cfg)
    [cfg, ~] = make_figure2_case('D', 'standard');
end
g_values = [0.8, 1.5];
runs = cell(size(g_values));
pre = cell(size(g_values));
post = cell(size(g_values));
summary = zeros(numel(g_values), 4);

for gi = 1:numel(g_values)
    run_cfg = cfg;
    run_cfg.g = g_values(gi);
    run_cfg.seed = cfg.seed;
    run_cfg.saveResults = false;
    run_cfg.makePlots = false;
    run_cfg.verbose = false;
    run_cfg.tag = sprintf('supplement_s2_g_%0.1f', g_values(gi));
    run_result = run_force_external(run_cfg);
    runs{gi} = run_result;
    pre{gi} = eig(run_result.M);
    post{gi} = eig(run_result.M + run_result.wf * run_result.wo');
    nearest_shift = min(abs(post{gi} - pre{gi}.'), [], 2);
    summary(gi, :) = [run_result.metrics.training_mae, ...
        run_result.metrics.testing_mae, mean(nearest_shift), max(nearest_shift)];
end

angular_frequencies = (1:4) * pi * cfg.freq;
result = struct('cfg', cfg, 'g_values', g_values, 'runs', {runs}, ...
    'pre_eigenvalues', {pre}, 'post_eigenvalues', {post}, ...
    'angular_frequencies', angular_frequencies, 'summary', summary);
if cfg.saveResults
    save(fullfile(cfg.dataDir, 'supplement_s2_eigenvalues.mat'), 'result', '-v7.3');
end
if cfg.makePlots
    save_plot(result);
end
end

function save_plot(result)
cfg = result.cfg;
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 440]);
for gi = 1:numel(result.g_values)
    subplot(1, 2, gi);
    plot(real(result.pre_eigenvalues{gi}), imag(result.pre_eigenvalues{gi}), ...
        'o', 'Color', [0.1 0.35 0.85], 'MarkerSize', 4); hold on;
    plot(real(result.post_eigenvalues{gi}), imag(result.post_eigenvalues{gi}), ...
        'ro', 'MarkerSize', 4);
    xline(1, 'k-');
    plot(zeros(size(result.angular_frequencies)), result.angular_frequencies, ...
        'gx', 'LineWidth', 1.5, 'MarkerSize', 8);
    plot(zeros(size(result.angular_frequencies)), -result.angular_frequencies, ...
        'gx', 'LineWidth', 1.5, 'MarkerSize', 8);
    hold off; axis equal; grid on; xlim([-2.5 2.0]); ylim([-1.8 1.8]);
    title(sprintf('%c: g = %.1f', 'A' + gi - 1, result.g_values(gi)));
    xlabel('Re(lambda)'); ylabel('Im(lambda)');
end
legend({'before', 'after', 'Re(lambda)=1', 'target frequencies'}, ...
    'Location', 'southoutside', 'Orientation', 'horizontal');
exportgraphics(fig, fullfile(cfg.figureDir, 'supplement_s2_eigenvalues.png'), 'Resolution', 200);
exportgraphics(fig, fullfile(cfg.figureDir, 'supplement_s2_eigenvalues.pdf'), 'ContentType', 'vector');
close(fig);
end
