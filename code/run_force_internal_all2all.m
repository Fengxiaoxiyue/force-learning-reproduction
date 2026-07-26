function result = run_force_internal_all2all(cfg)
%RUN_FORCE_INTERNAL_ALL2ALL Figure 1C all-to-all internal FORCE example.
%   This follows force_internal_all2all.m. FORCE/RLS modifies the readout
%   weights and applies the same low-rank update to the recurrent matrix.

if nargin < 1 || isempty(cfg)
    cfg = make_config('internal_smoke');
elseif ischar(cfg) || isstring(cfg)
    cfg = make_config(cfg);
end

if cfg.verbose
    fprintf('Running internal all-to-all preset "%s": N=%d, g=%.3f, nsecs=%.1f\n', ...
        cfg.preset, cfg.N, cfg.g, cfg.nsecs);
end

if ~exist(cfg.dataDir, 'dir')
    mkdir(cfg.dataDir);
end

rng(cfg.seed, 'twister');
tic;

N = cfg.N;
M = randn(N, N) * cfg.g / sqrt(N);
wo = zeros(N, 1);

simtime = cfg.simtime;
simtime2 = cfg.simtime2;
simtime_len = cfg.num_steps;
if isfield(cfg, 'target_train') && ~isempty(cfg.target_train)
    ft = cfg.target_train;
else
    ft = make_four_sine_target(simtime, cfg);
end
if isfield(cfg, 'target_test') && ~isempty(cfg.target_test)
    ft2 = cfg.target_test;
else
    ft2 = make_four_sine_target(simtime2, cfg);
end

wo_len = zeros(1, simtime_len);
zt = zeros(1, simtime_len);
zpt = zeros(1, simtime_len);

x = 0.5 * randn(N, 1);
r = tanh(x);
z = 0.5 * randn(1, 1);
P = (1.0 / cfg.alpha) * eye(N);

for ti = 1:simtime_len
    x = (1.0 - cfg.dt) * x + M * (r * cfg.dt);
    r = tanh(x);
    z = wo' * r;

    if mod(ti, cfg.learn_every) == 0
        e = z - ft(ti);
        [wo, P, dw] = rls_update(wo, P, r, e);
        M = M + repmat(dw', N, 1);
    end

    zt(ti) = z;
    wo_len(ti) = sqrt(wo' * wo);
end

for ti = 1:simtime_len
    x = (1.0 - cfg.dt) * x + M * (r * cfg.dt);
    r = tanh(x);
    z = wo' * r;
    zpt(ti) = z;
end

elapsed_seconds = toc;

result = struct();
result.cfg = cfg;
result.simtime = simtime;
result.simtime2 = simtime2;
result.ft = ft;
result.ft2 = ft2;
result.zt = zt;
result.zpt = zpt;
result.wo = wo;
result.wo_len = wo_len;
result.elapsed_seconds = elapsed_seconds;
result.metrics = compute_metrics(result);

if cfg.verbose
    fprintf('Training MAE: %.6f\n', result.metrics.training_mae);
    fprintf('Testing MAE: %.6f\n', result.metrics.testing_mae);
    fprintf('Elapsed seconds: %.2f\n', elapsed_seconds);
end

if cfg.saveResults
    dataPath = fullfile(cfg.dataDir, [cfg.tag, '.mat']);
    save(dataPath, 'result', '-v7.3');
end

if cfg.makePlots
    save_force_plots(result, cfg, cfg.tag);
end
end
