function result = run_figure2_one_shot(cfg)
%RUN_FIGURE2_ONE_SHOT Two-feedback-loop initialization for Figure 2J.
%   The exact aperiodic waveform was not published; a deterministic pulse
%   sequence is used while preserving the paper's two-stage learning logic.

cfg = apply_optional_defaults(cfg);
rng(cfg.seed, 'twister');
tic;
N = cfg.N;
M = full(sprandn(N, N, cfg.p)) * cfg.g / sqrt(cfg.p * N);
wf1 = 2 * (rand(N, 1) - 0.5);
wf2 = 2 * (rand(N, 1) - 0.5);
w1 = zeros(N, 1);
w2 = zeros(N, 1);
P1 = eye(N) / cfg.alpha;
P2 = eye(N) / cfg.alpha;
x = 0.5 * randn(N, 1);
r = tanh(x);

steps = cfg.num_steps;
init_steps = max(20, round(cfg.initialization_fraction * steps));
u = linspace(0, 1, steps);
target = 0.9 * exp(-((u - 0.20) / 0.07).^2) ...
    - 0.7 * exp(-((u - 0.48) / 0.10).^2) ...
    + 0.55 * exp(-((u - 0.73) / 0.05).^2);
target = target - target(1);

% Stage 1: learn a fixed point with both readout loops active.
for ti = 1:init_steps * cfg.fixed_point_repeats
    feedback1 = w1' * r;
    feedback2 = w2' * r;
    x = (1 - cfg.dt) * x + cfg.dt * (M * r + wf1 * feedback1 + wf2 * feedback2);
    r = tanh(x);
    z1 = w1' * r;
    z2 = w2' * r;
    [w1, P1] = rls_update(w1, P1, r, z1 - 1.0);
    [w2, P2] = rls_update(w2, P2, r, z2 - target(1));
end

% Stage 2: repeatedly initialize, deactivate loop 1, and learn the sequence.
training_trials = cfg.training_trials;
zt = zeros(1, steps);
trial_mae = zeros(1, training_trials);
for trial = 1:training_trials
    trial_output = zeros(1, steps);
    for ti = 1:steps
        feedback1 = w1' * r;
        feedback2 = w2' * r;
        active1 = ti <= init_steps;
        x = (1 - cfg.dt) * x + cfg.dt * (M * r + ...
            wf1 * (active1 * feedback1) + wf2 * feedback2);
        r = tanh(x);
        z2 = w2' * r;
        if mod(ti, cfg.learn_every) == 0
            [w2, P2] = rls_update(w2, P2, r, z2 - target(ti));
        end
        trial_output(ti) = z2;
    end
    trial_mae(trial) = mean(abs(trial_output - target));
    if trial == training_trials, zt = trial_output; end
end

zpt = zeros(1, steps);
for ti = 1:steps
    feedback1 = w1' * r;
    feedback2 = w2' * r;
    active1 = ti <= init_steps;
    x = (1 - cfg.dt) * x + cfg.dt * (M * r + ...
        wf1 * (active1 * feedback1) + wf2 * feedback2);
    r = tanh(x);
    zpt(ti) = w2' * r;
end

result = struct('cfg', cfg, 'simtime', cfg.simtime, 'simtime2', cfg.simtime2, ...
    'ft', target, 'ft2', target, 'zt', zt, 'zpt', zpt, 'wo', w2, ...
    'wo_len', repmat(norm(w2), 1, steps), 'initialization_steps', init_steps, ...
    'trial_mae', trial_mae, 'elapsed_seconds', toc);
result.metrics = compute_metrics(result);
if cfg.saveResults
    save(fullfile(cfg.dataDir, [cfg.tag, '.mat']), 'result', '-v7.3');
end
if cfg.makePlots
    save_force_plots(result, cfg, cfg.tag);
end
end

function cfg = apply_optional_defaults(cfg)
defaults = struct('training_trials', 12, 'fixed_point_repeats', 4, ...
    'initialization_fraction', 0.1);
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(cfg, names{i}), cfg.(names{i}) = defaults.(names{i}); end
end
end
