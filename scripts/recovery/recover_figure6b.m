%RECOVER_FIGURE6B Scaled Figure 1B feedback-network recovery attempts.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));
dataDir = fullfile(projectRoot, 'results', 'recovery', 'data');
figureDir = fullfile(projectRoot, 'results', 'recovery', 'figures');

attempts(1) = spec(1000, 0.025, 0.025, ...
    'recovery_figure6b_N1000_NF95_pfg025_pz025_init1');
attempts(2) = spec(1000, 0.025, 1.0, ...
    'recovery_figure6b_N1000_NF95_pfg025_pz100_init1');
attempts(3) = spec(1000, 0.1, 1.0, ...
    'recovery_figure6b_N1000_NF95_pfg100_pz100_init1');
attempts(4) = spec(1500, 100 / 1500, 1.0, ...
    'recovery_figure6b_N1500_NF95_inputs100_pz100_init1');

rowCount = numel(attempts);
networkSize = zeros(rowCount, 1);
feedbackInputCount = zeros(rowCount, 1);
readoutInputCount = zeros(rowCount, 1);
trainingMae = zeros(rowCount, 1);
testingMae = zeros(rowCount, 1);
testingCorr = zeros(rowCount, 1);
earlyAlignedCorr = zeros(rowCount, 1);
lateAlignedCorr = zeros(rowCount, 1);
frequencyRatio = zeros(rowCount, 1);
elapsedSeconds = zeros(rowCount, 1);

for i = 1:rowCount
    matPath = fullfile(dataDir, [attempts(i).tag, '.mat']);
    if exist(matPath, 'file')
        loaded = load(matPath, 'result');
        result = loaded.result;
    else
        [cfg, ~] = make_figure2_case('D', 'full');
        cfg.N = attempts(i).N;
        cfg.NF = 95;
        cfg.pFG = attempts(i).pFG;
        cfg.pz = attempts(i).pz;
        cfg.feedback_initial_scale = 1;
        cfg.dataDir = dataDir;
        cfg.figureDir = figureDir;
        cfg.tag = attempts(i).tag;
        result = run_force_feedback_network(cfg);
    end
    result.recovery_metrics = compute_recovery_metrics(result, 1200);
    save(matPath, 'result', '-v7.3');
    metrics = result.recovery_metrics;
    networkSize(i) = result.cfg.N;
    feedbackInputCount(i) = numel(result.feedback_inputs{1});
    readoutInputCount(i) = numel(result.output_inputs);
    trainingMae(i) = metrics.training_mae;
    testingMae(i) = metrics.testing_mae;
    testingCorr(i) = metrics.testing_corr;
    earlyAlignedCorr(i) = metrics.phase_aligned_corr;
    lateAlignedCorr(i) = metrics.late_phase_aligned_corr;
    frequencyRatio(i) = metrics.frequency_ratio;
    elapsedSeconds(i) = metrics.elapsed_seconds;
end

summary = table(networkSize, feedbackInputCount, readoutInputCount, ...
    trainingMae, testingMae, testingCorr, earlyAlignedCorr, ...
    lateAlignedCorr, frequencyRatio, elapsedSeconds);
writetable(summary, fullfile(dataDir, 'recovery_figure6b_summary.csv'));
disp(summary);

function value = spec(N, pFG, pz, tag)
value = struct('N', N, 'pFG', pFG, 'pz', pz, 'tag', tag);
end
