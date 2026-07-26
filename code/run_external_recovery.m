function summary = run_external_recovery(case_id, attempt_specs)
%RUN_EXTERNAL_RECOVERY Run and retain high-cost Figure 1A attempts.

if nargin < 2 || isempty(attempt_specs)
    attempt_specs = struct('N', 1000, 'seed_offset', 0, 'g', 1.5, 'alpha', 1.0);
end
project_root = fileparts(fileparts(mfilename('fullpath')));
data_dir = fullfile(project_root, 'results', 'recovery', 'data');
figure_dir = fullfile(project_root, 'results', 'recovery', 'figures');
if ~exist(data_dir, 'dir'), mkdir(data_dir); end
if ~exist(figure_dir, 'dir'), mkdir(figure_dir); end

row_count = numel(attempt_specs);
attempt_id = strings(row_count, 1);
network_size = zeros(row_count, 1);
g = zeros(row_count, 1);
alpha = zeros(row_count, 1);
seed = zeros(row_count, 1);
training_mae = zeros(row_count, 1);
testing_mae = zeros(row_count, 1);
testing_corr = zeros(row_count, 1);
phase_aligned_mae = zeros(row_count, 1);
phase_aligned_corr = zeros(row_count, 1);
late_phase_aligned_mae = zeros(row_count, 1);
late_phase_aligned_corr = zeros(row_count, 1);
phase_lag_drift_steps = zeros(row_count, 1);
amplitude_ratio = zeros(row_count, 1);
frequency_ratio = zeros(row_count, 1);
elapsed_seconds = zeros(row_count, 1);

for ai = 1:row_count
    [cfg, info] = make_figure2_case(case_id, 'full');
    spec = apply_spec_defaults(attempt_specs(ai));
    cfg.N = spec.N;
    cfg.g = spec.g;
    cfg.alpha = spec.alpha;
    cfg.seed = cfg.seed + spec.seed_offset;
    cfg.dataDir = data_dir;
    cfg.figureDir = figure_dir;
    cfg.tag = sprintf('recovery_figure2_%s_N%d_g_%0.2f_a_%0.2f_seed_%d', ...
        lower(case_id), cfg.N, cfg.g, cfg.alpha, cfg.seed);
    cfg.tag = strrep(cfg.tag, '.', 'p');
    cfg.verbose = true;
    result = run_force_external(cfg);
    recovery_metrics = compute_recovery_metrics(result, target_period_steps(case_id, cfg));
    result.recovery_metrics = recovery_metrics;
    result.target_info = info;
    save(fullfile(data_dir, [cfg.tag, '.mat']), 'result', '-v7.3');

    attempt_id(ai) = cfg.tag;
    network_size(ai) = cfg.N;
    g(ai) = cfg.g;
    alpha(ai) = cfg.alpha;
    seed(ai) = cfg.seed;
    training_mae(ai) = recovery_metrics.training_mae;
    testing_mae(ai) = recovery_metrics.testing_mae;
    testing_corr(ai) = recovery_metrics.testing_corr;
    phase_aligned_mae(ai) = recovery_metrics.phase_aligned_mae;
    phase_aligned_corr(ai) = recovery_metrics.phase_aligned_corr;
    late_phase_aligned_mae(ai) = recovery_metrics.late_phase_aligned_mae;
    late_phase_aligned_corr(ai) = recovery_metrics.late_phase_aligned_corr;
    phase_lag_drift_steps(ai) = recovery_metrics.phase_lag_drift_steps;
    amplitude_ratio(ai) = recovery_metrics.amplitude_ratio;
    frequency_ratio(ai) = recovery_metrics.frequency_ratio;
    elapsed_seconds(ai) = recovery_metrics.elapsed_seconds;
end

new_summary = table(attempt_id, network_size, g, alpha, seed, training_mae, ...
    testing_mae, testing_corr, phase_aligned_mae, phase_aligned_corr, ...
    late_phase_aligned_mae, late_phase_aligned_corr, phase_lag_drift_steps, ...
    amplitude_ratio, frequency_ratio, elapsed_seconds);
csv_name = sprintf('recovery_figure2_%s_summary.csv', lower(case_id));
csv_path = fullfile(data_dir, csv_name);
if exist(csv_path, 'file')
    summary = readtable(csv_path, 'TextType', 'string');
    missing = setdiff(new_summary.Properties.VariableNames, summary.Properties.VariableNames);
    if ~isempty(missing)
        summary = refresh_external_recovery_summary(case_id);
    end
    summary(ismember(summary.attempt_id, new_summary.attempt_id), :) = [];
    summary = [summary; new_summary];
else
    summary = new_summary;
end
writetable(summary, csv_path);
disp(summary);
end

function spec = apply_spec_defaults(spec)
defaults = struct('N', 1000, 'seed_offset', 0, 'g', 1.5, 'alpha', 1.0);
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(spec, names{i}), spec.(names{i}) = defaults.(names{i}); end
end
end

function steps = target_period_steps(case_id, cfg)
switch upper(case_id)
    case 'I_FAST'
        period = 6;
    case 'I_SLOW'
        period = 800;
    otherwise
        period = 120;
end
steps = max(2, round(period / cfg.dt));
end
