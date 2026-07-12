%RUN_SWEEP Small parameter sweep for explaining tuning behavior.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

base = make_config('sweep');
base.saveResults = false;
base.makePlots = false;

g_values = [0.8, 1.2, 1.5, 1.8];
alpha_values = [0.5, 1.0, 2.0];

rows = [];
run_id = 0;
for gi = 1:numel(g_values)
    for ai = 1:numel(alpha_values)
        run_id = run_id + 1;
        cfg = base;
        cfg.g = g_values(gi);
        cfg.alpha = alpha_values(ai);
        cfg.seed = base.seed + run_id;
        cfg.tag = sprintf('sweep_g%.1f_alpha%.1f', cfg.g, cfg.alpha);
        cfg.verbose = true;

        result = run_force_external(cfg);
        rows = [rows; run_id, cfg.g, cfg.alpha, result.metrics.training_mae, ...
            result.metrics.testing_mae, result.metrics.final_weight_norm, ...
            result.metrics.testing_corr]; %#ok<AGROW>
    end
end

sweep_table = array2table(rows, 'VariableNames', ...
    {'run_id', 'g', 'alpha', 'training_mae', 'testing_mae', ...
    'final_weight_norm', 'testing_corr'});

if ~exist(base.dataDir, 'dir')
    mkdir(base.dataDir);
end
save(fullfile(base.dataDir, 'sweep_summary.mat'), 'sweep_table');
writetable(sweep_table, fullfile(base.dataDir, 'sweep_summary.csv'));

disp(sweep_table);
fprintf('Sweep summary saved to %s\n', fullfile(base.dataDir, 'sweep_summary.csv'));
