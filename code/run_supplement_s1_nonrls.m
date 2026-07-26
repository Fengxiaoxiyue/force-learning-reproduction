function result = run_supplement_s1_nonrls(cfg)
%RUN_SUPPLEMENT_S1_NONRLS FORCE learning with a scalar adaptive rate.
%   Implements Supplementary Equations 1 and 3 without an RLS matrix.

if nargin < 1 || isempty(cfg)
    cfg = make_config('smoke');
end
cfg = apply_defaults(cfg);
if ~exist(cfg.dataDir, 'dir'), mkdir(cfg.dataDir); end
if ~exist(cfg.figureDir, 'dir'), mkdir(cfg.figureDir); end

rng(cfg.seed, 'twister');
N = cfg.N;
M = sprandn(N, N, cfg.p) * cfg.g / sqrt(cfg.p * N);
if ~cfg.use_sparse_recurrent, M = full(M); end
wf = cfg.feedback_scale * (rand(N, 1) - 0.5);
w = zeros(N, 1);
x = 0.5 * randn(N, 1);
r = tanh(x);
z = 0;
eta = cfg.eta_initial;

t_train = 0:cfg.dt:(cfg.nsecs - cfg.dt);
t_test = cfg.nsecs:cfg.dt:(cfg.nsecs + cfg.test_nsecs - cfg.dt);
target_train = periodic_target(t_train, cfg.target_amplitude);
target_test = periodic_target(t_test, cfg.target_amplitude);
output_train = zeros(size(t_train));
output_test = zeros(size(t_test));
eta_history = zeros(size(t_train));
weight_speed = zeros(size(t_train));

tic;
for ti = 1:numel(t_train)
    x = (1 - cfg.dt) * x + cfg.dt * (M * r + wf * z);
    r = tanh(x);
    z = w' * r;
    error_before = z - target_train(ti);

    if mod(ti, cfg.learn_every) == 0
        delta_w = -eta * error_before * r;
        w = w + delta_w;
        weight_speed(ti) = norm(delta_w) / cfg.dt;
        eta = eta + cfg.dt * eta * (-eta + abs(error_before)^cfg.eta_exponent);
        eta = max(eta, realmin('double'));
    end
    output_train(ti) = z;
    eta_history(ti) = eta;
end

for ti = 1:numel(t_test)
    x = (1 - cfg.dt) * x + cfg.dt * (M * r + wf * z);
    r = tanh(x);
    z = w' * r;
    output_test(ti) = z;
end
elapsed_seconds = toc;

tail = max(1, numel(t_train) - round(600 / cfg.dt) + 1):numel(t_train);
metrics = struct( ...
    'training_tail_mae', mean(abs(output_train(tail) - target_train(tail))), ...
    'testing_mae', mean(abs(output_test - target_test)), ...
    'eta_initial', cfg.eta_initial, ...
    'eta_final', eta, ...
    'elapsed_seconds', elapsed_seconds);
periodic_result = struct('cfg', cfg, 'ft', target_train, 'ft2', target_test, ...
    'zt', output_train, 'zpt', output_test, 'wo_len', ones(size(output_train)), ...
    'elapsed_seconds', elapsed_seconds);
recovery_metrics = compute_recovery_metrics(periodic_result, round(60 / cfg.dt));
metrics.testing_corr = recovery_metrics.testing_corr;
metrics.phase_aligned_corr = recovery_metrics.phase_aligned_corr;
metrics.late_phase_aligned_corr = recovery_metrics.late_phase_aligned_corr;
metrics.amplitude_ratio = recovery_metrics.amplitude_ratio;
metrics.frequency_ratio = recovery_metrics.frequency_ratio;
result = struct('cfg', cfg, 't_train', t_train, 't_test', t_test, ...
    'target_train', target_train, 'target_test', target_test, ...
    'output_train', output_train, 'output_test', output_test, ...
    'eta_history', eta_history, 'weight_speed', weight_speed, ...
    'w', w, 'M', M, 'wf', wf, 'metrics', metrics);

if cfg.saveResults
    save(fullfile(cfg.dataDir, [cfg.tag, '.mat']), 'result', '-v7.3');
end
if cfg.makePlots
    save_plot(result);
end
end

function cfg = apply_defaults(cfg)
defaults = struct('eta_initial', 2e-3, 'eta_exponent', 1.5, ...
    'target_amplitude', 0.1, 'test_nsecs', 600, ...
    'use_sparse_recurrent', true, 'tag', 'supplement_s1_nonrls');
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(cfg, names{i}), cfg.(names{i}) = defaults.(names{i}); end
end
end

function y = periodic_target(t, amplitude)
y = amplitude * sin(2 * pi * t / 60);
end

function save_plot(result)
cfg = result.cfg;
tail_count = min(numel(result.t_train), round(600 / cfg.dt));
tail = numel(result.t_train) - tail_count + 1:numel(result.t_train);
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 620]);
subplot(2, 2, 1);
plot(result.t_train(tail), result.target_train(tail), 'Color', [0.9 0.55 0.1], 'LineWidth', 1.3); hold on;
plot(result.t_train(tail), result.output_train(tail), 'r'); hold off; grid on;
title('A: final training interval'); xlabel('time / tau'); ylabel('output');
subplot(2, 2, 2);
plot(result.t_test, result.target_test, 'Color', [0.9 0.55 0.1], 'LineWidth', 1.3); hold on;
plot(result.t_test, result.output_test, 'r'); hold off; grid on;
title('A: static-weight test'); xlabel('time / tau'); ylabel('output');
subplot(2, 2, [3 4]);
plot_stride = max(1, ceil(numel(result.t_train) / 5000));
plot_idx = 1:plot_stride:numel(result.t_train);
semilogy(result.t_train(plot_idx), result.eta_history(plot_idx), ...
    'k', 'LineWidth', 1.1); grid on;
title('B: adaptive scalar learning rate'); xlabel('time / tau'); ylabel('eta');
exportgraphics(fig, fullfile(cfg.figureDir, [cfg.tag, '.png']), 'Resolution', 200);
exportgraphics(fig, fullfile(cfg.figureDir, [cfg.tag, '.pdf']), 'ContentType', 'vector');
close(fig);
end
