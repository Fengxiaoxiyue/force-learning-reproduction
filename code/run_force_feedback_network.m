function result = run_force_feedback_network(cfg)
%RUN_FORCE_FEEDBACK_NETWORK Figure 1B generator-feedback architecture.

if ~isfield(cfg, 'NF'), cfg.NF = max(20, round(cfg.N / 8)); end
if ~isfield(cfg, 'gGF'), cfg.gGF = 1.0; end
if ~isfield(cfg, 'gFG'), cfg.gFG = 1.0; end
if ~isfield(cfg, 'gFF'), cfg.gFF = 1.2; end
if ~isfield(cfg, 'pGF'), cfg.pGF = 0.25; end
if ~isfield(cfg, 'pFG'), cfg.pFG = min(0.25, max(0.05, 50 / cfg.N)); end
if ~isfield(cfg, 'pFF'), cfg.pFF = 0.25; end
if ~isfield(cfg, 'pz'), cfg.pz = 1.0; end
if ~isfield(cfg, 'feedback_initial_scale'), cfg.feedback_initial_scale = 1.0; end

rng(cfg.seed, 'twister');
N = cfg.N;
NF = cfg.NF;
Mgg = full(sprandn(N, N, cfg.p)) * cfg.g / sqrt(cfg.p * N);
Mff = full(sprandn(NF, NF, cfg.pFF)) * cfg.gFF / sqrt(cfg.pFF * NF);
Jgf = full(sprandn(N, NF, cfg.pGF)) * cfg.gGF / sqrt(cfg.pGF * NF);
Jfg = zeros(NF, N);
feedback_inputs = cell(NF, 1);
Pfb = cell(NF, 1);
input_count = max(4, round(cfg.pFG * N));
for a = 1:NF
    idx = randperm(N, input_count);
    feedback_inputs{a} = idx;
    Jfg(a, idx) = cfg.feedback_initial_scale * cfg.gFG * randn(1, input_count) / sqrt(input_count);
    Pfb{a} = eye(input_count) / cfg.alpha;
end
initial_feedback_weight_norm = norm(Jfg, 'fro');
output_count = max(4, round(cfg.pz * N));
output_inputs = randperm(N, output_count);
wo = zeros(N, 1);
P = eye(output_count) / cfg.alpha;
x = 0.5 * randn(N, 1);
y = 0.5 * randn(NF, 1);
r = tanh(x);
s = tanh(y);

steps = cfg.num_steps;
zt = zeros(1, steps);
zpt = zeros(1, steps);
wo_len = zeros(1, steps);
tic;
for ti = 1:steps
    x = (1 - cfg.dt) * x + cfg.dt * (Mgg * r + Jgf * s);
    y = (1 - cfg.dt) * y + cfg.dt * (Mff * s + Jfg * r);
    r = tanh(x);
    s = tanh(y);
    z = wo(output_inputs)' * r(output_inputs);
    if mod(ti, cfg.learn_every) == 0
        e = z - cfg.target_train(ti);
        output_weights = wo(output_inputs);
        [output_weights, P] = rls_update(output_weights, P, r(output_inputs), e);
        wo(output_inputs) = output_weights;
        for a = 1:NF
            idx = feedback_inputs{a};
            weights = Jfg(a, idx)';
            [weights, Pfb{a}] = rls_update(weights, Pfb{a}, r(idx), e);
            Jfg(a, idx) = weights';
        end
    end
    zt(ti) = z;
    wo_len(ti) = norm(wo);
end
for ti = 1:steps
    x = (1 - cfg.dt) * x + cfg.dt * (Mgg * r + Jgf * s);
    y = (1 - cfg.dt) * y + cfg.dt * (Mff * s + Jfg * r);
    r = tanh(x);
    s = tanh(y);
    zpt(ti) = wo(output_inputs)' * r(output_inputs);
end

result = struct('cfg', cfg, 'simtime', cfg.simtime, 'simtime2', cfg.simtime2, ...
    'ft', cfg.target_train, 'ft2', cfg.target_test, 'zt', zt, 'zpt', zpt, ...
    'wo', wo, 'wo_len', wo_len, 'elapsed_seconds', toc, ...
    'output_inputs', output_inputs, 'feedback_inputs', {feedback_inputs}, ...
    'Jfg', Jfg, 'initial_feedback_weight_norm', initial_feedback_weight_norm, ...
    'final_feedback_weight_norm', norm(Jfg, 'fro'));
result.metrics = compute_metrics(result);
if cfg.saveResults
    save(fullfile(cfg.dataDir, [cfg.tag, '.mat']), 'result', '-v7.3');
end
if cfg.makePlots
    save_force_plots(result, cfg, cfg.tag);
end
end
