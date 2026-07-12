%RUN_SMOKE Quick external FORCE run for checking the workflow.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

cfg = make_config('smoke');
result = run_force_external(cfg);

fprintf('\nSmoke run complete.\n');
fprintf('Training MAE: %.6f\n', result.metrics.training_mae);
fprintf('Testing MAE: %.6f\n', result.metrics.testing_mae);
fprintf('Output data: %s\n', fullfile(cfg.dataDir, [cfg.tag, '.mat']));
fprintf('Output figure: %s\n', fullfile(cfg.figureDir, [cfg.tag, '_traces.png']));
