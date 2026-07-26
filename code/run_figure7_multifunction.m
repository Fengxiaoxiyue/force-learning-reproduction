function result = run_figure7_multifunction(cfg)
%RUN_FIGURE7_MULTIFUNCTION Five static-input-selected periodic outputs.

rng(cfg.seed, 'twister');
N = cfg.N;
pattern_count = 5;
M = randn(N, N) * cfg.g / sqrt(N);
Win = randn(N, pattern_count) / sqrt(pattern_count);
w = zeros(N, 1);
P = eye(N) / cfg.alpha;
x = 0.5 * randn(N, 1);
r = tanh(x);
steps = round(120 / cfg.dt);
group_size = floor(N / pattern_count);
groups = cell(pattern_count, 1);
for p = 1:pattern_count
    groups{p} = (p-1)*group_size + (1:group_size);
end
t = (0:steps-1) * cfg.dt;
targets = zeros(pattern_count, steps);
for p = 1:pattern_count
    targets(p, :) = 0.7 * sin(2*pi*t/120 + p) + 0.3 * sin(4*pi*t/120 + 0.3*p) ...
        + 0.2 * sin(6*pi*t/120 + 0.7*p);
end

for epoch = 1:10
    for p = 1:pattern_count
        control = zeros(pattern_count, 1); control(p) = 0.5;
        for ti = 1:steps
            x = (1-cfg.dt)*x + cfg.dt*(M*r + Win*control);
            r = tanh(x);
            z = w' * r;
            if mod(ti, cfg.learn_every) == 0
                [w, P, dw] = rls_update(w, P, r, z-targets(p,ti));
                idx = groups{p};
                M(idx, :) = M(idx, :) + repmat(dw', numel(idx), 1);
            end
        end
    end
end

outputs = zeros(pattern_count, steps);
for p = 1:pattern_count
    control = zeros(pattern_count, 1); control(p) = 0.5;
    for ti = 1:steps
        x = (1-cfg.dt)*x + cfg.dt*(M*r + Win*control);
        r = tanh(x);
        outputs(p,ti) = w' * r;
    end
end
mae = mean(abs(outputs-targets), 2);
result = struct('targets', targets, 'outputs', outputs, 'mae', mae, 'time', t, 'cfg', cfg);
save(fullfile(cfg.dataDir, 'figure7_multifunction.mat'), 'result', '-v7.3');

fig=figure('Visible','off','Color','w','Position',[100 100 900 600]);
for p=1:pattern_count
    subplot(pattern_count,1,p); plot(t,targets(p,:),'g',t,outputs(p,:),'r'); ylabel(sprintf('P%d',p)); grid on;
end
xlabel('time / tau');
exportgraphics(fig,fullfile(cfg.figureDir,'figure7_multifunction.png'),'Resolution',200);
exportgraphics(fig,fullfile(cfg.figureDir,'figure7_multifunction.pdf'),'ContentType','vector'); close(fig);
end
