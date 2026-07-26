function summary = run_figure4_feedback_sweep()
%RUN_FIGURE4_FEEDBACK_SWEEP FORCE-to-echo-state feedback interpolation.

base = make_figure2_case('D', 'standard');
base.N = 500;
base.nsecs = 720;
base.simtime = 0:base.dt:(base.nsecs - base.dt);
base.simtime2 = base.nsecs:base.dt:(2 * base.nsecs - base.dt);
base.num_steps = numel(base.simtime);
base.target_train = make_four_sine_target(base.simtime, base);
base.target_test = make_four_sine_target(base.simtime2, base);
base.seed = 200901;
base.saveResults = false;
base.makePlots = false;
base.verbose = false;
gammas = 0:0.1:1;
trials = 5;
stable = false(numel(gammas), trials);
mae = nan(numel(gammas), trials);

for gi = 1:numel(gammas)
    for trial = 1:trials
        cfg = base;
        cfg.feedback_mode = 'mixed';
        cfg.feedback_mix_gamma = gammas(gi);
        cfg.seed = base.seed + trial - 1;
        result = run_force_external(cfg);
        mae(gi, trial) = result.metrics.testing_mae;
        stable(gi, trial) = result.metrics.testing_corr > 0.9 && mae(gi, trial) < 0.2;
    end
end

summary = table(gammas', 100 * mean(stable, 2), mean(mae, 2, 'omitnan'), ...
    std(mae, 0, 2, 'omitnan'), 'VariableNames', {'gamma', 'percent_stable', 'mean_mae', 'std_mae'});
writetable(summary, fullfile(base.dataDir, 'figure4_feedback_sweep.csv'));
save(fullfile(base.dataDir, 'figure4_feedback_sweep.mat'), 'summary', 'stable', 'mae');

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 900, 360]);
subplot(1, 2, 1); plot(summary.gamma, summary.percent_stable, 'ko-', 'LineWidth', 1.2); ylim([0 105]);
xlabel('\gamma'); ylabel('% stable'); title('A: stability'); grid on;
subplot(1, 2, 2); errorbar(summary.gamma, summary.mean_mae, summary.std_mae, 'ko-', 'LineWidth', 1.2);
xlabel('\gamma'); ylabel('MAE'); title('B: post-training error'); grid on;
exportgraphics(fig, fullfile(base.figureDir, 'figure4_feedback_sweep.png'), 'Resolution', 200);
exportgraphics(fig, fullfile(base.figureDir, 'figure4_feedback_sweep.pdf'), 'ContentType', 'vector');
close(fig);
end
