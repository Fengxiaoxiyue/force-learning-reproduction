%RECOVER_FIGURE2_J Corrected and scaled one-shot learning attempts.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));

networkSize = [300; 500];
trainingTrials = [12; 24];
trainingMae = zeros(2, 1);
testingMae = zeros(2, 1);
testingCorr = zeros(2, 1);
elapsedSeconds = zeros(2, 1);

for i = 1:numel(networkSize)
    cfg = make_config('smoke');
    cfg.N = networkSize(i);
    cfg.nsecs = 240;
    cfg.simtime = 0:cfg.dt:(cfg.nsecs - cfg.dt);
    cfg.simtime2 = cfg.nsecs:cfg.dt:(2 * cfg.nsecs - cfg.dt);
    cfg.num_steps = numel(cfg.simtime);
    cfg.training_trials = trainingTrials(i);
    cfg.dataDir = fullfile(projectRoot, 'results', 'recovery', 'data');
    cfg.figureDir = fullfile(projectRoot, 'results', 'recovery', 'figures');
    cfg.tag = sprintf('recovery_figure2_j_N%d_trials%d_a1', ...
        cfg.N, cfg.training_trials);
    result = run_figure2_one_shot(cfg);
    trainingMae(i) = result.metrics.training_mae;
    testingMae(i) = result.metrics.testing_mae;
    testingCorr(i) = result.metrics.testing_corr;
    elapsedSeconds(i) = result.elapsed_seconds;
end

summary = table(networkSize, trainingTrials, trainingMae, testingMae, ...
    testingCorr, elapsedSeconds);
writetable(summary, fullfile(projectRoot, 'results', 'recovery', 'data', ...
    'recovery_figure2_j_summary.csv'));
disp(summary);
