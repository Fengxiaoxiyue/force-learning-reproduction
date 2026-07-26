function result = run_figure2_one_shot(cfg)
%RUN_FIGURE2_ONE_SHOT Two-feedback-loop initialization for Figure 2J.
%   The exact aperiodic waveform was not published; a deterministic pulse
%   sequence is used while preserving the paper's two-stage learning logic.

rng(cfg.seed, 'twister');
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
init_steps = max(20, round(0.1 * steps));
u = linspace(0, 1, steps);
target = 0.9 * exp(-((u - 0.20) / 0.07).^2) ...
    - 0.7 * exp(-((u - 0.48) / 0.10).^2) ...
    + 0.55 * exp(-((u - 0.73) / 0.05).^2);
target = target - target(1);

% Stage 1: learn a fixed point with both readout loops active.
for ti = 1:init_steps * 4
    z1 = w1' * r;
    z2 = w2' * r;
    x = (1 - cfg.dt) * x + cfg.dt * (M * r + wf1 * z1 + wf2 * z2);
    r = tanh(x);
    [w1, P1] = rls_update(w1, P1, r, z1 - 1.0);
    [w2, P2] = rls_update(w2, P2, r, z2 - target(1));
end

% Stage 2: repeatedly initialize, deactivate loop 1, and learn the sequence.
training_trials = 12;
zt = zeros(1, steps);
for trial = 1:training_trials
    for ti = 1:steps
        z1 = w1' * r;
        z2 = w2' * r;
        active1 = ti <= init_steps;
        x = (1 - cfg.dt) * x + cfg.dt * (M * r + wf1 * (active1 * z1) + wf2 * z2);
        r = tanh(x);
        if mod(ti, cfg.learn_every) == 0
            [w2, P2] = rls_update(w2, P2, r, z2 - target(ti));
        end
        if trial == training_trials
            zt(ti) = z2;
        end
    end
end

zpt = zeros(1, steps);
for ti = 1:steps
    z1 = w1' * r;
    z2 = w2' * r;
    active1 = ti <= init_steps;
    x = (1 - cfg.dt) * x + cfg.dt * (M * r + wf1 * (active1 * z1) + wf2 * z2);
    r = tanh(x);
    zpt(ti) = z2;
end

result = struct('cfg', cfg, 'simtime', cfg.simtime, 'simtime2', cfg.simtime2, ...
    'ft', target, 'ft2', target, 'zt', zt, 'zpt', zpt, 'wo', w2, ...
    'wo_len', repmat(norm(w2), 1, steps), 'initialization_steps', init_steps);
result.metrics = compute_metrics(result);
if cfg.saveResults
    save(fullfile(cfg.dataDir, [cfg.tag, '.mat']), 'result', '-v7.3');
end
if cfg.makePlots
    save_force_plots(result, cfg, cfg.tag);
end
end
