function result = run_force_external(cfg)
%RUN_FORCE_EXTERNAL Reproduce Figure 2D with Figure 1A external feedback.
%   This is a modular version of force_external_feedback_loop.m from the
%   supplemental Matlab examples. The recurrent matrix and feedback weights
%   are fixed; FORCE/RLS modifies only the readout weights.

if nargin < 1 || isempty(cfg)
    cfg = make_config('smoke');
elseif ischar(cfg) || isstring(cfg)
    cfg = make_config(cfg);
end

if cfg.verbose
    fprintf('Running external FORCE preset "%s": N=%d, g=%.3f, nsecs=%.1f\n', ...
        cfg.preset, cfg.N, cfg.g, cfg.nsecs);
end

if ~exist(cfg.dataDir, 'dir')
    mkdir(cfg.dataDir);
end

rng(cfg.seed, 'twister');
tic;

N = cfg.N;
scale = 1.0 / sqrt(cfg.p * N);
M = sprandn(N, N, cfg.p) * cfg.g * scale;
M = full(M);

wo = zeros(N, 1);
wf = cfg.feedback_scale * (rand(N, 1) - 0.5);

simtime = cfg.simtime;
simtime2 = cfg.simtime2;
simtime_len = cfg.num_steps;
ft = make_four_sine_target(simtime, cfg);
ft2 = make_four_sine_target(simtime2, cfg);

wo_len = zeros(1, simtime_len);
zt = zeros(1, simtime_len);
zpt = zeros(1, simtime_len);

x = 0.5 * randn(N, 1);
r = tanh(x);
z = 0.5 * randn(1, 1);
P = (1.0 / cfg.alpha) * eye(N);

for ti = 1:simtime_len
    x = (1.0 - cfg.dt) * x + M * (r * cfg.dt) + wf * (z * cfg.dt);
    r = tanh(x);
    z = wo' * r;

    if mod(ti, cfg.learn_every) == 0
        e = z - ft(ti);
        [wo, P] = rls_update(wo, P, r, e);
    end

    zt(ti) = z;
    wo_len(ti) = sqrt(wo' * wo);
end

training_mae = mean(abs(zt - ft));
if cfg.verbose
    fprintf('Training MAE: %.6f\n', training_mae);
end

for ti = 1:simtime_len
    x = (1.0 - cfg.dt) * x + M * (r * cfg.dt) + wf * (z * cfg.dt);
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
