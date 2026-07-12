%RUN_REPRODUCTION Full Figure 2D / Figure 1A external FORCE reproduction.
% This run uses the same scale as the supplemental Matlab example and may
% take several minutes depending on the machine.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

cfg = make_config('reproduction');
result = run_force_external(cfg);

fprintf('\nReproduction run complete.\n');
fprintf('Training MAE: %.6f\n', result.metrics.training_mae);
fprintf('Testing MAE: %.6f\n', result.metrics.testing_mae);
fprintf('Testing correlation: %.6f\n', result.metrics.testing_corr);
fprintf('Output data: %s\n', fullfile(cfg.dataDir, [cfg.tag, '.mat']));
fprintf('Output figure: %s\n', fullfile(cfg.figureDir, [cfg.tag, '_traces.png']));
