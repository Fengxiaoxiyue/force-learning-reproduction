function summary = refresh_external_recovery_summary(case_id)
%REFRESH_EXTERNAL_RECOVERY_SUMMARY Recompute diagnostics from saved MAT files.

project_root = fileparts(fileparts(mfilename('fullpath')));
data_dir = fullfile(project_root, 'results', 'recovery', 'data');
pattern = sprintf('recovery_figure2_%s_N*.mat', lower(case_id));
files = dir(fullfile(data_dir, pattern));
assert(~isempty(files), 'No recovery MAT files found for case %s.', case_id);

records = repmat(struct(), numel(files), 1);
for i = 1:numel(files)
    loaded = load(fullfile(files(i).folder, files(i).name), 'result');
    result = loaded.result;
    metrics = compute_recovery_metrics(result, target_period_steps(case_id, result.cfg));
    result.recovery_metrics = metrics;
    save(fullfile(files(i).folder, files(i).name), 'result', '-v7.3');
    records(i).attempt_id = string(erase(files(i).name, '.mat'));
    records(i).network_size = result.cfg.N;
    records(i).training_duration = result.cfg.nsecs;
    records(i).g = result.cfg.g;
    records(i).alpha = result.cfg.alpha;
    records(i).seed = result.cfg.seed;
    records(i).training_mae = metrics.training_mae;
    records(i).testing_mae = metrics.testing_mae;
    records(i).testing_corr = metrics.testing_corr;
    records(i).phase_aligned_mae = metrics.phase_aligned_mae;
    records(i).phase_aligned_corr = metrics.phase_aligned_corr;
    records(i).late_phase_aligned_mae = metrics.late_phase_aligned_mae;
    records(i).late_phase_aligned_corr = metrics.late_phase_aligned_corr;
    records(i).phase_lag_drift_steps = metrics.phase_lag_drift_steps;
    records(i).amplitude_ratio = metrics.amplitude_ratio;
    records(i).frequency_ratio = metrics.frequency_ratio;
    records(i).elapsed_seconds = metrics.elapsed_seconds;
end

summary = struct2table(records);
writetable(summary, fullfile(data_dir, ...
    sprintf('recovery_figure2_%s_summary.csv', lower(case_id))));
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
