function analysis = analyze_figure3_pca(cfg)
%ANALYZE_FIGURE3_PCA Reproduce the PCA diagnostics in Figure 3.

cfg.store_rates = true;
cfg.store_weight_history = true;
cfg.history_stride = max(1, round(1 / cfg.dt));
cfg.saveResults = false;
cfg.makePlots = false;
result = run_force_external(cfg);

R = double(result.rates);
mean_r = mean(R, 2);
X = R - mean_r;
[U, S, ~] = svd(X, 'econ');
eigenvalues = diag(S).^2 / max(1, size(X, 2) - 1);
top_count = min(8, size(U, 2));
R8 = mean_r + U(:, 1:top_count) * (U(:, 1:top_count)' * X);
z8 = result.wo' * R8;

W = double(result.wo_history);
projection_count = min(80, size(U, 2));
weight_projections = U(:, 1:projection_count)' * W;

analysis = struct('cfg', cfg, 'result_metrics', result.metrics, ...
    'history_time', result.history_time, 'eigenvalues', eigenvalues, ...
    'pc_scores', U(:, 1:top_count)' * X, 'z_sampled', result.zt(1:cfg.history_stride:end), ...
    'z8', z8, 'weight_projections', weight_projections);

save(fullfile(cfg.dataDir, 'figure3_pca.mat'), 'analysis', '-v7.3');

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [50, 50, 1200, 760]);
subplot(2, 3, 1);
plot(analysis.history_time, analysis.z_sampled, 'r', analysis.history_time, z8, 'Color', [0.45, 0.25, 0.1]);
title('A: output and 8-PC reconstruction'); grid on;
subplot(2, 3, 2);
plot(analysis.history_time, analysis.pc_scores'); title('B: leading PC scores'); grid on;
subplot(2, 3, 3);
semilogy(eigenvalues(1:min(100, numel(eigenvalues))), 'k.-'); title('C: PCA eigenvalues'); grid on;
subplot(2, 3, 4);
imagesc(log10(max(eigenvalues(1:min(100, end)), eps))); colorbar; title('D: control-learning spectrum');
subplot(2, 3, 5);
plot(weight_projections(1, :), weight_projections(2, :), 'LineWidth', 1.2); title('E: weights on PC1-PC2'); grid on;
subplot(2, 3, 6);
pc80 = min(80, size(weight_projections, 1));
plot3(weight_projections(1, :), weight_projections(2, :), weight_projections(pc80, :), 'LineWidth', 1.2);
title(sprintf('F: weights on PC1-PC2-PC%d', pc80)); grid on;
exportgraphics(fig, fullfile(cfg.figureDir, 'figure3_pca.png'), 'Resolution', 200);
exportgraphics(fig, fullfile(cfg.figureDir, 'figure3_pca.pdf'), 'ContentType', 'vector');
close(fig);
end
