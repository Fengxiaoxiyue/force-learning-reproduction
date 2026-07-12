%RUN_INTERNAL_ALL2ALL Figure 1C all-to-all internal FORCE extension.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

cfg = make_config('internal_smoke');
result = run_force_internal_all2all(cfg);

fprintf('\nInternal all-to-all run complete.\n');
fprintf('Training MAE: %.6f\n', result.metrics.training_mae);
fprintf('Testing MAE: %.6f\n', result.metrics.testing_mae);
fprintf('Output data: %s\n', fullfile(cfg.dataDir, [cfg.tag, '.mat']));
fprintf('Output figure: %s\n', fullfile(cfg.figureDir, [cfg.tag, '_traces.png']));
