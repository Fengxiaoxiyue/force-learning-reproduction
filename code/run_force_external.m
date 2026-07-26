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

cfg = apply_optional_defaults(cfg);

rng(cfg.seed, 'twister');
tic;

N = cfg.N;
scale = 1.0 / sqrt(cfg.p * N);
M = sprandn(N, N, cfg.p) * cfg.g * scale;
M = full(M);

wo = cfg.wo_init_scale * randn(N, 1) / sqrt(N);
wf = cfg.feedback_scale * (rand(N, 1) - 0.5);

simtime = cfg.simtime;
simtime2 = cfg.simtime2;
simtime_len = cfg.num_steps;
if isempty(cfg.target_train)
    ft = make_four_sine_target(simtime, cfg);
else
    ft = cfg.target_train;
end
if isempty(cfg.target_test)
    ft2 = make_four_sine_target(simtime2, cfg);
else
    ft2 = cfg.target_test;
end
validateattributes(ft, {'numeric'}, {'row', 'numel', simtime_len, 'finite'});
validateattributes(ft2, {'numeric'}, {'row', 'numel', simtime_len, 'finite'});

wo_len = zeros(1, simtime_len);
zt = zeros(1, simtime_len);
zpt = zeros(1, simtime_len);
dw_norm = zeros(1, simtime_len);
z_history = zeros(1, simtime_len);

sample_count = ceil(simtime_len / cfg.history_stride);
if cfg.store_rates
    rates = zeros(N, sample_count, 'single');
else
    rates = [];
end
if cfg.store_weight_history
    wo_history = zeros(N, sample_count, 'single');
else
    wo_history = [];
end
sample_index = 0;

x = 0.5 * randn(N, 1);
r = tanh(x);
z = 0.5 * randn(1, 1);
P = (1.0 / cfg.alpha) * eye(N);

for ti = 1:simtime_len
    feedback_value = training_feedback(z, z_history, ti, ft, cfg);
    x = (1.0 - cfg.dt) * x + M * (r * cfg.dt) + wf * (feedback_value * cfg.dt);
    r = tanh(x);
    z = wo' * r;
    z_history(ti) = z;

    if mod(ti, cfg.learn_every) == 0
        e = z - ft(ti);
        [wo, P, dw] = rls_update(wo, P, r, e);
        dw_norm(ti) = norm(dw);
    end

    zt(ti) = z;
    wo_len(ti) = sqrt(wo' * wo);
    if mod(ti - 1, cfg.history_stride) == 0
        sample_index = sample_index + 1;
        if cfg.store_rates
            rates(:, sample_index) = single(r);
        end
        if cfg.store_weight_history
            wo_history(:, sample_index) = single(wo);
        end
    end
end

training_mae = mean(abs(zt - ft));
if cfg.verbose
    fprintf('Training MAE: %.6f\n', training_mae);
end

for ti = 1:simtime_len
    feedback_value = testing_feedback(z, zpt, ti, cfg);
    x = (1.0 - cfg.dt) * x + M * (r * cfg.dt) + wf * (feedback_value * cfg.dt);
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
result.dw_norm = dw_norm;
result.rates = rates;
result.wo_history = wo_history;
result.history_time = simtime(1:cfg.history_stride:end);
result.M = M;
result.wf = wf;
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

function cfg = apply_optional_defaults(cfg)
defaults = struct( ...
    'target_train', [], ...
    'target_test', [], ...
    'wo_init_scale', 0.0, ...
    'feedback_mode', 'force', ...
    'feedback_mix_gamma', 0.0, ...
    'feedback_delay_steps', 1, ...
    'feedback_nonlinear_gain', 1.3, ...
    'store_rates', false, ...
    'store_weight_history', false, ...
    'history_stride', 1);
names = fieldnames(defaults);
for i = 1:numel(names)
    name = names{i};
    if ~isfield(cfg, name)
        cfg.(name) = defaults.(name);
    end
end
end

function value = training_feedback(z, history, ti, target, cfg)
switch lower(cfg.feedback_mode)
    case 'force'
        value = z;
    case 'mixed'
        gamma = cfg.feedback_mix_gamma;
        value = gamma * target(ti) + (1 - gamma) * z;
    case 'delayed_nonlinear'
        idx = max(1, ti - cfg.feedback_delay_steps);
        delayed_z = history(idx);
        value = cfg.feedback_nonlinear_gain * tanh(sin(pi * delayed_z));
    otherwise
        error('run_force_external:feedbackMode', ...
            'Unknown feedback mode: %s', cfg.feedback_mode);
end
end

function value = testing_feedback(z, history, ti, cfg)
if strcmpi(cfg.feedback_mode, 'delayed_nonlinear')
    idx = max(1, ti - cfg.feedback_delay_steps);
    delayed_z = history(idx);
    value = cfg.feedback_nonlinear_gain * tanh(sin(pi * delayed_z));
else
    value = z;
end
end
