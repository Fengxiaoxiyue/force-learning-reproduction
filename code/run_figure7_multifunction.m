function result = run_figure7_multifunction(cfg)
%RUN_FIGURE7_MULTIFUNCTION Static-input-selected periodic outputs.
%   Uses a shared-P low-rank approximation for internal FORCE updates. The
%   exact sparse-row algorithm requires one large inverse-correlation matrix
%   per modified neuron and is not practical at the published scale here.

cfg = apply_optional_defaults(cfg);
rng(cfg.seed, 'twister');
tic;

N = cfg.N;
pattern_count = cfg.pattern_count;
steps = round(cfg.pattern_duration / cfg.dt);
initialization_steps = round(cfg.initialization_duration / cfg.dt);
modified_count = min(cfg.modified_count, N);

M = full(sprandn(N, N, cfg.p)) * cfg.g / sqrt(cfg.p * N);
input_weights = zeros(N, cfg.input_count);
for neuron = 1:N
    input_weights(neuron, randi(cfg.input_count)) = randn;
end
initialization_patterns = -2 + 4 * rand(cfg.input_count, pattern_count);
control_patterns = -0.5 + rand(cfg.input_count, pattern_count);
modified_rows = randperm(N, modified_count);

w = zeros(N, 1);
P = eye(N) / cfg.alpha;
x = 0.5 * randn(N, 1);
r = tanh(x);
t = (0:steps-1) * cfg.dt;
targets = make_targets(pattern_count, t, cfg.pattern_duration);
epoch_mae = zeros(cfg.epochs, pattern_count);

for epoch = 1:cfg.epochs
    for pattern = 1:pattern_count
        init_target = targets(pattern, 1);
        for ti = 1:initialization_steps
            x = (1 - cfg.dt) * x + cfg.dt * ...
                (M * r + input_weights * initialization_patterns(:, pattern));
            r = tanh(x);
            z = w' * r;
            if mod(ti, cfg.learn_every) == 0
                [w, P, dw] = rls_update(w, P, r, z - init_target);
                M(modified_rows, :) = M(modified_rows, :) + dw';
            end
        end

        pattern_output = zeros(1, steps);
        for ti = 1:steps
            x = (1 - cfg.dt) * x + cfg.dt * ...
                (M * r + input_weights * control_patterns(:, pattern));
            r = tanh(x);
            z = w' * r;
            if mod(ti, cfg.learn_every) == 0
                [w, P, dw] = rls_update(w, P, r, z - targets(pattern, ti));
                M(modified_rows, :) = M(modified_rows, :) + dw';
            end
            pattern_output(ti) = z;
        end
        epoch_mae(epoch, pattern) = mean(abs(pattern_output - targets(pattern, :)));
    end
end

outputs = zeros(pattern_count, steps);
for pattern = 1:pattern_count
    for ti = 1:initialization_steps
        x = (1 - cfg.dt) * x + cfg.dt * ...
            (M * r + input_weights * initialization_patterns(:, pattern));
        r = tanh(x);
    end
    for ti = 1:steps
        x = (1 - cfg.dt) * x + cfg.dt * ...
            (M * r + input_weights * control_patterns(:, pattern));
        r = tanh(x);
        outputs(pattern, ti) = w' * r;
    end
end

mae = mean(abs(outputs - targets), 2);
correlation = zeros(pattern_count, 1);
for pattern = 1:pattern_count
    values = corrcoef(outputs(pattern, :), targets(pattern, :));
    correlation(pattern) = values(1, 2);
end
result = struct('targets', targets, 'outputs', outputs, 'mae', mae, ...
    'correlation', correlation, 'time', t, 'cfg', cfg, ...
    'epoch_mae', epoch_mae, 'modified_rows', modified_rows, ...
    'initialization_patterns', initialization_patterns, ...
    'control_patterns', control_patterns, 'elapsed_seconds', toc);

if cfg.saveResults
    save(fullfile(cfg.dataDir, [cfg.tag, '.mat']), 'result', '-v7.3');
end
if cfg.makePlots
    save_plots(result);
end
end

function targets = make_targets(pattern_count, t, period)
targets = zeros(pattern_count, numel(t));
for pattern = 1:pattern_count
    targets(pattern, :) = 0.7 * sin(2*pi*t/period + pattern) ...
        + 0.3 * sin(4*pi*t/period + 0.3*pattern) ...
        + 0.2 * sin(6*pi*t/period + 0.7*pattern);
end
end

function save_plots(result)
cfg = result.cfg;
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 600]);
for pattern = 1:cfg.pattern_count
    subplot(cfg.pattern_count, 1, pattern);
    plot(result.time, result.targets(pattern, :), 'g', ...
        result.time, result.outputs(pattern, :), 'r');
    ylabel(sprintf('P%d', pattern));
    grid on;
end
xlabel('time / tau');
exportgraphics(fig, fullfile(cfg.figureDir, [cfg.tag, '.png']), 'Resolution', 200);
exportgraphics(fig, fullfile(cfg.figureDir, [cfg.tag, '.pdf']), 'ContentType', 'vector');
close(fig);
end

function cfg = apply_optional_defaults(cfg)
defaults = struct('pattern_count', 5, 'input_count', 100, 'epochs', 10, ...
    'pattern_duration', 120, 'initialization_duration', 20, ...
    'modified_count', min(800, round(2 * cfg.N / 3)), ...
    'tag', 'figure7_multifunction', 'saveResults', true, 'makePlots', true);
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(cfg, names{i}), cfg.(names{i}) = defaults.(names{i}); end
end
end
