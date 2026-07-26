%RECOVER_FIGURE2_H Evaluate Lorenz generation with chaos-aware metrics.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));

networkSize = [1000; 1500];
trainingMae = zeros(2, 1);
pointwiseMae = zeros(2, 1);
pointwiseCorr = zeros(2, 1);
short100Corr = zeros(2, 1);
short500Corr = zeros(2, 1);
normalizedQuantileMae = zeros(2, 1);
stdRatio = zeros(2, 1);
logPsdCorr = zeros(2, 1);
autocorrelationMae = zeros(2, 1);
elapsedSeconds = zeros(2, 1);

for i = 1:numel(networkSize)
    [cfg, info] = make_figure2_case('H', 'full');
    cfg.N = networkSize(i);
    cfg.dataDir = fullfile(projectRoot, 'results', 'recovery', 'data');
    cfg.figureDir = fullfile(projectRoot, 'results', 'recovery', 'figures');
    cfg.tag = sprintf('recovery_figure2_h_N%d_g1p50_a1', cfg.N);
    result = run_force_external(cfg);
    result.chaos_metrics = compute_chaos_metrics(result);
    result.target_info = info;
    save(fullfile(cfg.dataDir, [cfg.tag, '.mat']), 'result', '-v7.3');

    chaos = result.chaos_metrics;
    trainingMae(i) = result.metrics.training_mae;
    pointwiseMae(i) = chaos.pointwise_mae;
    pointwiseCorr(i) = chaos.pointwise_corr;
    short100Corr(i) = chaos.short_horizon_corr(chaos.horizon_steps == 100);
    short500Corr(i) = chaos.short_horizon_corr(chaos.horizon_steps == 500);
    normalizedQuantileMae(i) = chaos.normalized_quantile_mae;
    stdRatio(i) = chaos.std_ratio;
    logPsdCorr(i) = chaos.log_psd_corr;
    autocorrelationMae(i) = chaos.autocorrelation_mae;
    elapsedSeconds(i) = result.elapsed_seconds;
end

summary = table(networkSize, trainingMae, pointwiseMae, pointwiseCorr, ...
    short100Corr, short500Corr, normalizedQuantileMae, stdRatio, ...
    logPsdCorr, autocorrelationMae, elapsedSeconds);
writetable(summary, fullfile(projectRoot, 'results', 'recovery', 'data', ...
    'recovery_figure2_h_summary.csv'));
disp(summary);
