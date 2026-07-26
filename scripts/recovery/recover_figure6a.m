%RECOVER_FIGURE6A Delayed nonlinear-feedback stability attempts.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));
dataDir = fullfile(projectRoot, 'results', 'recovery', 'data');
figureDir = fullfile(projectRoot, 'results', 'recovery', 'figures');

attempts(1) = spec(1000, 50, 1.3);
attempts(2) = spec(1000, 100, 1.0);
attempts(3) = spec(1000, 100, 1.3);
attempts(4) = spec(1000, 100, 1.6);
attempts(5) = spec(1000, 150, 1.3);
attempts(6) = spec(1500, 100, 1.3);

rowCount = numel(attempts);
networkSize = zeros(rowCount, 1);
delayMs = zeros(rowCount, 1);
nonlinearGain = zeros(rowCount, 1);
trainingMae = zeros(rowCount, 1);
testingMae = zeros(rowCount, 1);
testingCorr = zeros(rowCount, 1);
earlyAlignedCorr = zeros(rowCount, 1);
lateAlignedCorr = zeros(rowCount, 1);
frequencyRatio = zeros(rowCount, 1);
elapsedSeconds = zeros(rowCount, 1);

for i = 1:rowCount
    tag = sprintf('recovery_figure6a_N%d_delay%dms_gain%.1f_continuous', ...
        attempts(i).N, attempts(i).delayMs, attempts(i).gain);
    tag = strrep(tag, '.', 'p');
    matPath = fullfile(dataDir, [tag, '.mat']);
    if exist(matPath, 'file')
        loaded = load(matPath, 'result');
        result = loaded.result;
    else
        [cfg, ~] = make_figure2_case('D', 'full');
        cfg.N = attempts(i).N;
        cfg.feedback_mode = 'delayed_nonlinear';
        cfg.feedback_delay_steps = round((attempts(i).delayMs / 10) / cfg.dt);
        cfg.feedback_nonlinear_gain = attempts(i).gain;
        cfg.dataDir = dataDir;
        cfg.figureDir = figureDir;
        cfg.tag = tag;
        result = run_force_external(cfg);
    end
    if ~isfield(result, 'test_history_prefix')
        delaySteps = result.cfg.feedback_delay_steps;
        result.test_history_prefix = result.zt(end - delaySteps + 1:end);
    end
    result.recovery_metrics = compute_recovery_metrics(result, 1200);
    save(matPath, 'result', '-v7.3');
    metrics = result.recovery_metrics;
    networkSize(i) = result.cfg.N;
    delayMs(i) = attempts(i).delayMs;
    nonlinearGain(i) = attempts(i).gain;
    trainingMae(i) = metrics.training_mae;
    testingMae(i) = metrics.testing_mae;
    testingCorr(i) = metrics.testing_corr;
    earlyAlignedCorr(i) = metrics.phase_aligned_corr;
    lateAlignedCorr(i) = metrics.late_phase_aligned_corr;
    frequencyRatio(i) = metrics.frequency_ratio;
    elapsedSeconds(i) = metrics.elapsed_seconds;
end

summary = table(networkSize, delayMs, nonlinearGain, trainingMae, testingMae, ...
    testingCorr, earlyAlignedCorr, lateAlignedCorr, frequencyRatio, elapsedSeconds);
writetable(summary, fullfile(dataDir, 'recovery_figure6a_summary.csv'));
disp(summary);

function value = spec(N, delayMs, gain)
value = struct('N', N, 'delayMs', delayMs, 'gain', gain);
end
