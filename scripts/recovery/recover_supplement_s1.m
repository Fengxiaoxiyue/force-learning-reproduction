%RECOVER_SUPPLEMENT_S1 High-cost non-RLS FORCE stability attempts.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));
dataDir = fullfile(projectRoot, 'results', 'recovery', 'data');
figureDir = fullfile(projectRoot, 'results', 'recovery', 'figures');

attempts(1) = spec(300, 2101, 1.5, 'supplement_s1_nonrls');
attempts(2) = spec(500, 2101, 1.5, 'recovery_s1_N500_sparse_60000tau');
attempts(3) = spec(1000, 2101, 1.5, 'recovery_s1_N1000_sparse_60000tau');
attempts(4) = spec(1000, 2101, 2.0, 'recovery_s1_N1000_sparse_60000tau_gamma2');
attempts(5) = spec(1000, 2102, 1.5, 'recovery_s1_N1000_sparse_60000tau_seed2102');
attempts(6) = spec(1000, 2103, 1.5, 'recovery_s1_N1000_sparse_60000tau_seed2103');

rowCount = numel(attempts);
networkSize = zeros(rowCount, 1);
seed = zeros(rowCount, 1);
etaExponent = zeros(rowCount, 1);
trainingTailMae = zeros(rowCount, 1);
testingMae = zeros(rowCount, 1);
testingCorr = zeros(rowCount, 1);
phaseAlignedCorr = zeros(rowCount, 1);
amplitudeRatio = zeros(rowCount, 1);
frequencyRatio = zeros(rowCount, 1);
etaFinal = zeros(rowCount, 1);
elapsedSeconds = zeros(rowCount, 1);

for i = 1:rowCount
    if i == 1
        matPath = fullfile(projectRoot, 'results', 'data', [attempts(i).tag, '.mat']);
    else
        matPath = fullfile(dataDir, [attempts(i).tag, '.mat']);
    end
    if exist(matPath, 'file')
        loaded = load(matPath, 'result');
        result = loaded.result;
    else
        cfg = make_config('smoke');
        cfg.N = attempts(i).N;
        cfg.nsecs = 60000;
        cfg.test_nsecs = 600;
        cfg.learn_every = 1;
        cfg.seed = attempts(i).seed;
        cfg.eta_exponent = attempts(i).etaExponent;
        cfg.dataDir = dataDir;
        cfg.figureDir = figureDir;
        cfg.tag = attempts(i).tag;
        result = run_supplement_s1_nonrls(cfg);
    end
    if ~isfield(result.metrics, 'phase_aligned_corr')
        adapter = struct('cfg', result.cfg, 'ft', result.target_train, ...
            'ft2', result.target_test, 'zt', result.output_train, ...
            'zpt', result.output_test, 'wo_len', ones(size(result.output_train)), ...
            'elapsed_seconds', result.metrics.elapsed_seconds);
        recovery = compute_recovery_metrics(adapter, round(60 / result.cfg.dt));
        result.metrics.testing_corr = recovery.testing_corr;
        result.metrics.phase_aligned_corr = recovery.phase_aligned_corr;
        result.metrics.amplitude_ratio = recovery.amplitude_ratio;
        result.metrics.frequency_ratio = recovery.frequency_ratio;
    end
    metrics = result.metrics;
    networkSize(i) = result.cfg.N;
    seed(i) = result.cfg.seed;
    if isfield(result.cfg, 'eta_exponent')
        etaExponent(i) = result.cfg.eta_exponent;
    else
        etaExponent(i) = 1.5;
    end
    trainingTailMae(i) = metrics.training_tail_mae;
    testingMae(i) = metrics.testing_mae;
    testingCorr(i) = metrics.testing_corr;
    phaseAlignedCorr(i) = metrics.phase_aligned_corr;
    amplitudeRatio(i) = metrics.amplitude_ratio;
    frequencyRatio(i) = metrics.frequency_ratio;
    etaFinal(i) = metrics.eta_final;
    elapsedSeconds(i) = metrics.elapsed_seconds;
end

summary = table(networkSize, seed, etaExponent, trainingTailMae, testingMae, ...
    testingCorr, phaseAlignedCorr, amplitudeRatio, frequencyRatio, ...
    etaFinal, elapsedSeconds);
writetable(summary, fullfile(dataDir, 'recovery_supplement_s1_summary.csv'));
disp(summary);

function value = spec(N, seed, etaExponent, tag)
value = struct('N', N, 'seed', seed, 'etaExponent', etaExponent, 'tag', tag);
end
