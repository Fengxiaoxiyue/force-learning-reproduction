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

[case_cfg, case_info] = make_figure2_case('H', 'standard');
assert(numel(case_cfg.target_train) == case_cfg.num_steps, 'Figure 2 target length mismatch.');
assert(all(isfinite(case_cfg.target_train)), 'Figure 2 target contains non-finite values.');
assert(case_info.exact, 'Lorenz target should be marked as exact from published parameters.');

chaos_fixture = struct('ft2', sin(0:0.01:20), 'zpt', sin(0:0.01:20));
chaos_metrics = compute_chaos_metrics(chaos_fixture);
assert(chaos_metrics.pointwise_mae < eps, 'Identical chaos signals have nonzero MAE.');
assert(abs(chaos_metrics.log_psd_corr - 1) < 1e-12, ...
    'Identical chaos signals should have equal spectra.');
assert(chaos_metrics.autocorrelation_mae < eps, ...
    'Identical chaos signals should have equal autocorrelation.');

one_shot_cfg = make_config('test');
one_shot_cfg.tag = 'test_one_shot';
one_shot = run_figure2_one_shot(one_shot_cfg);
assert(all(isfinite(one_shot.zpt)), 'One-shot output contains non-finite values.');
assert(numel(one_shot.trial_mae) == one_shot.cfg.training_trials, ...
    'One-shot trial history length mismatch.');
assert(all(isfinite(one_shot.trial_mae)), ...
    'One-shot trial history contains non-finite values.');

feedback_cfg = make_config('test');
feedback_cfg.NF = 6;
feedback_cfg.target_train = make_four_sine_target(feedback_cfg.simtime, feedback_cfg);
feedback_cfg.target_test = make_four_sine_target(feedback_cfg.simtime2, feedback_cfg);
feedback_result = run_force_feedback_network(feedback_cfg);
assert(all(isfinite(feedback_result.zpt)), 'Feedback-network output contains non-finite values.');

pca_cfg = make_figure2_case('D', 'standard');
pca_cfg.N = 30;
pca_cfg.nsecs = 6;
pca_cfg.simtime = 0:pca_cfg.dt:(pca_cfg.nsecs - pca_cfg.dt);
pca_cfg.simtime2 = pca_cfg.nsecs:pca_cfg.dt:(2 * pca_cfg.nsecs - pca_cfg.dt);
pca_cfg.num_steps = numel(pca_cfg.simtime);
pca_cfg.target_train = make_four_sine_target(pca_cfg.simtime, pca_cfg);
pca_cfg.target_test = make_four_sine_target(pca_cfg.simtime2, pca_cfg);
pca_cfg.makePlots = false;
pca_cfg.saveResults = false;
pca_cfg.store_rates = true;
pca_result = run_force_external(pca_cfg);
assert(size(pca_result.rates, 1) == pca_cfg.N, 'Stored rate history has wrong size.');

[motion_test, motion_labels] = read_amc_motion(fullfile(projectRoot, 'data', 'raw', 'mocap', '09_02.amc'));
assert(~isempty(motion_test) && size(motion_test, 2) == numel(motion_labels), 'AMC parser failed.');

s1_cfg = make_config('test');
s1_cfg.nsecs = 1;
s1_cfg.test_nsecs = 1;
s1_result = run_supplement_s1_nonrls(s1_cfg);
assert(isfinite(s1_result.metrics.eta_final) && s1_result.metrics.eta_final > 0, ...
    'Non-RLS adaptive learning rate became invalid.');

metric_cfg = make_config('test');
metric_result = struct('cfg', metric_cfg, 'ft', sin(0:0.1:6-0.1), ...
    'ft2', sin(0:0.1:6-0.1), 'zt', sin(0:0.1:6-0.1), ...
    'zpt', circshift(sin(0:0.1:6-0.1), 7), 'wo_len', ones(1, 60), ...
    'elapsed_seconds', 0);
recovery_metrics = compute_recovery_metrics(metric_result, 60);
assert(recovery_metrics.phase_aligned_corr > 0.99, ...
    'Phase-aligned recovery metric failed on a shifted periodic signal.');
assert(recovery_metrics.late_phase_aligned_corr > 0.99, ...
    'Late-cycle recovery metric failed on a shifted periodic signal.');

fprintf('All tests passed.\n');
