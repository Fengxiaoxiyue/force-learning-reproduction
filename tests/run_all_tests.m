%RUN_ALL_TESTS Lightweight checks for the FORCE reproduction code.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

fprintf('Running FORCE reproduction tests...\n');

cfg = make_config('test');
t = cfg.simtime;
ft = make_four_sine_target(t, cfg);
assert(isrow(ft), 'Target function should be a row vector.');
assert(numel(ft) == numel(t), 'Target function length must match time axis.');
assert(all(isfinite(ft)), 'Target function contains non-finite values.');
assert(max(abs(ft)) < 3.0, 'Target amplitude is unexpectedly large.');

w = zeros(5, 1);
P = eye(5);
r = linspace(-0.4, 0.4, 5)';
[w2, P2, dw, info] = rls_update(w, P, r, 0.25);
assert(isequal(size(w2), [5, 1]), 'Updated weight vector has wrong size.');
assert(isequal(size(P2), [5, 5]), 'Updated inverse correlation matrix has wrong size.');
assert(isequal(size(dw), [5, 1]), 'Weight increment has wrong size.');
assert(norm(P2 - P2', 'fro') < 1e-10, 'P should remain symmetric.');
assert(isfield(info, 'rPr') && isfield(info, 'c'), 'RLS diagnostic info missing fields.');

cfg1 = make_config('test');
r1 = run_force_external(cfg1);
r2 = run_force_external(cfg1);
assert(max(abs(r1.zt - r2.zt)) < 1e-12, 'Fixed seed run is not reproducible.');
assert(max(abs(r1.zpt - r2.zpt)) < 1e-12, 'Fixed seed test output is not reproducible.');
assert(all(isfinite(r1.zt)) && all(isfinite(r1.zpt)), 'Simulation output contains non-finite values.');
assert(isfinite(r1.metrics.training_mae), 'Training MAE is not finite.');
assert(isfinite(r1.metrics.testing_mae), 'Testing MAE is not finite.');

fprintf('All tests passed.\n');
