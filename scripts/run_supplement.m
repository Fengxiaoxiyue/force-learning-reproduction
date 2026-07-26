%RUN_SUPPLEMENT Reproduce Supplementary Figures S1 and S2.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

cfg1 = make_config('smoke');
cfg1.N = 300;
cfg1.nsecs = 60000; % Full 60,000 tau duration reported for Figure S1.
cfg1.test_nsecs = 600;
cfg1.learn_every = 1;
cfg1.seed = 2101;
result1 = run_supplement_s1_nonrls(cfg1); %#ok<NASGU>

[cfg2, ~] = make_figure2_case('D', 'standard');
cfg2.N = 300;
cfg2.nsecs = 720;
cfg2.simtime = 0:cfg2.dt:(cfg2.nsecs - cfg2.dt);
cfg2.simtime2 = cfg2.nsecs:cfg2.dt:(2 * cfg2.nsecs - cfg2.dt);
cfg2.num_steps = numel(cfg2.simtime);
cfg2.target_train = make_four_sine_target(cfg2.simtime, cfg2);
cfg2.target_test = make_four_sine_target(cfg2.simtime2, cfg2);
cfg2.seed = 2102;
result2 = analyze_supplement_s2_eigenvalues(cfg2); %#ok<NASGU>

case_id = {'S1'; 'S1'; 'S2-g0.8'; 'S2-g1.5'};
metric_name = {'training_tail_mae'; 'testing_mae'; ...
    'max_spectral_shift'; 'max_spectral_shift'};
metric_value = [result1.metrics.training_tail_mae; result1.metrics.testing_mae; ...
    result2.summary(1, 4); result2.summary(2, 4)];
interpretation = {'training-following'; 'scaled-failure'; ...
    'large-outlier-shift'; 'distributed-small-shift'};
summary = table(case_id, metric_name, metric_value, interpretation);
writetable(summary, fullfile(projectRoot, 'results', 'data', 'supplement_summary.csv'));

fprintf('Supplementary Figures S1-S2 complete.\n');
