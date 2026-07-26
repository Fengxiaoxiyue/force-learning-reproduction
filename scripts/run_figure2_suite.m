%RUN_FIGURE2_SUITE Reproduce all Figure 2 output examples.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

case_ids = {'ABC', 'D', 'E', 'F', 'G', 'H', 'I_FAST', 'I_SLOW', 'K'};
summary = cell(numel(case_ids) + 3, 7);
row = 0;
for i = 1:numel(case_ids)
    [cfg, info] = make_figure2_case(case_ids{i}, 'full');
    result = run_force_external(cfg);
    row = row + 1;
    summary(row, :) = {case_ids{i}, '1A', info.exact, result.metrics.training_mae, ...
        result.metrics.testing_mae, result.metrics.testing_corr, info.note};
end

% Representative architecture comparison requested for Figure 2D.
[cfg_b, info_b] = make_figure2_case('D', 'full');
cfg_b.tag = 'figure2_d_architecture_1b';
result_b = run_force_feedback_network(cfg_b);
row = row + 1;
summary(row, :) = {'D', '1B', info_b.exact, result_b.metrics.training_mae, ...
    result_b.metrics.testing_mae, result_b.metrics.testing_corr, info_b.note};

[cfg_c, info_c] = make_figure2_case('D', 'full');
cfg_c.tag = 'figure2_d_architecture_1c';
cfg_c.p = 1.0;
cfg_c.amp = 0.7;
cfg_c.target_train = make_four_sine_target(cfg_c.simtime, cfg_c);
cfg_c.target_test = make_four_sine_target(cfg_c.simtime2, cfg_c);
result_c = run_force_internal_all2all(cfg_c);
row = row + 1;
summary(row, :) = {'D', '1C', info_c.exact, result_c.metrics.training_mae, ...
    result_c.metrics.testing_mae, result_c.metrics.testing_corr, info_c.note};

cfg_j = make_config('smoke');
cfg_j.N = 300;
cfg_j.nsecs = 240;
cfg_j.simtime = 0:cfg_j.dt:(cfg_j.nsecs - cfg_j.dt);
cfg_j.simtime2 = cfg_j.nsecs:cfg_j.dt:(2 * cfg_j.nsecs - cfg_j.dt);
cfg_j.num_steps = numel(cfg_j.simtime);
cfg_j.tag = 'figure2_j_one_shot';
result_j = run_figure2_one_shot(cfg_j);
row = row + 1;
summary(row, :) = {'J', '1A-two-loop', false, result_j.metrics.training_mae, ...
    result_j.metrics.testing_mae, result_j.metrics.testing_corr, ...
    'Deterministic one-shot waveform; original numerical waveform was not published.'};

summary_table = cell2table(summary, 'VariableNames', ...
    {'case_id', 'architecture', 'exact_target', 'training_mae', 'testing_mae', 'testing_corr', 'note'});
writetable(summary_table, fullfile(projectRoot, 'results', 'data', 'figure2_summary.csv'));
disp(summary_table);
