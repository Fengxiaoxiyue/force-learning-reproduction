function summary = run_figure5_gain_sweep()
%RUN_FIGURE5_GAIN_SWEEP Reproduce chaos-benefit diagnostics versus gain g.

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
g_values = 0.75:0.1:1.55;
trials = 3;
cycles = nan(numel(g_values), trials);
rmse = nan(numel(g_values), trials);
weight_norm = nan(numel(g_values), trials);
cycle_steps = round(120 / base.dt);

for gi = 1:numel(g_values)
    for trial = 1:trials
        cfg = base;
        cfg.g = g_values(gi);
        cfg.seed = base.seed + trial - 1;
        result = run_force_external(cfg);
        errors = abs(result.zt - result.ft);
        cycle_count = floor(numel(errors) / cycle_steps);
        for c = 1:cycle_count
            idx = (c - 1) * cycle_steps + (1:cycle_steps);
            if mean(errors(idx)) < 0.02
                cycles(gi, trial) = c;
                break;
            end
        end
        rmse(gi, trial) = result.metrics.testing_rmse;
        weight_norm(gi, trial) = result.metrics.final_weight_norm;
    end
end

summary = table(g_values', mean(cycles, 2, 'omitnan'), mean(rmse, 2), mean(weight_norm, 2), ...
    'VariableNames', {'g', 'mean_cycles', 'mean_testing_rmse', 'mean_weight_norm'});
writetable(summary, fullfile(base.dataDir, 'figure5_gain_sweep.csv'));
save(fullfile(base.dataDir, 'figure5_gain_sweep.mat'), 'summary', 'cycles', 'rmse', 'weight_norm');

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [50, 50, 1100, 340]);
subplot(1, 3, 1); plot(summary.g, summary.mean_cycles, 'ko-'); xlabel('g'); ylabel('cycles'); title('A: training cycles'); grid on;
subplot(1, 3, 2); plot(summary.g, summary.mean_testing_rmse, 'ko-'); xlabel('g'); ylabel('RMS error'); title('B: test error'); grid on;
subplot(1, 3, 3); plot(summary.g, summary.mean_weight_norm, 'ko-'); xlabel('g'); ylabel('||w||_2'); title('C: weight norm'); grid on;
exportgraphics(fig, fullfile(base.figureDir, 'figure5_gain_sweep.png'), 'Resolution', 200);
exportgraphics(fig, fullfile(base.figureDir, 'figure5_gain_sweep.pdf'), 'ContentType', 'vector');
close(fig);
end
