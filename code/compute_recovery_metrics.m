function metrics = compute_recovery_metrics(result, period_steps)
%COMPUTE_RECOVERY_METRICS Diagnostics for costly periodic recovery runs.

if nargin < 2 || isempty(period_steps)
    period_steps = numel(result.zpt);
end
period_steps = min(period_steps, numel(result.zpt));

target = result.ft2(:)';
output = result.zpt(:)';
base = compute_metrics(result);
metrics = base;
metrics.amplitude_ratio = std(output) / max(std(target), eps);

segment_target = target(1:period_steps);
segment_output = output(1:period_steps);
[metrics.phase_aligned_mae, metrics.phase_aligned_corr, ...
    metrics.phase_lag_steps] = align_cycle(segment_output, segment_target);

late_target = target(end-period_steps+1:end);
late_output = output(end-period_steps+1:end);
[metrics.late_phase_aligned_mae, metrics.late_phase_aligned_corr, ...
    metrics.late_phase_lag_steps] = align_cycle(late_output, late_target);
metrics.phase_lag_drift_steps = metrics.late_phase_lag_steps - metrics.phase_lag_steps;

metrics.output_dominant_frequency = dominant_frequency(output, result.cfg.dt);
metrics.target_dominant_frequency = dominant_frequency(target, result.cfg.dt);
metrics.frequency_ratio = metrics.output_dominant_frequency / ...
    max(metrics.target_dominant_frequency, eps);
end

function [mae, correlation, lag] = align_cycle(output, target)
cross_spectrum = fft(output) .* conj(fft(target));
[~, peak_index] = max(real(ifft(cross_spectrum)));
lag = peak_index - 1;
candidate_a = circshift(output, -lag);
candidate_b = circshift(output, lag);
if mean(abs(candidate_b - target)) < mean(abs(candidate_a - target))
    aligned = candidate_b;
    lag = -lag;
else
    aligned = candidate_a;
end
mae = mean(abs(aligned - target));
if std(aligned) > eps && std(target) > eps
    corr_matrix = corrcoef(aligned, target);
    correlation = corr_matrix(1, 2);
else
    correlation = double(max(abs(aligned - target)) < 1e-10);
end
end

function frequency = dominant_frequency(signal, dt)
centered = signal - mean(signal);
spectrum = abs(fft(centered));
positive_count = floor(numel(signal) / 2);
spectrum = spectrum(1:max(2, positive_count));
spectrum(1) = 0;
[~, index] = max(spectrum);
frequency = (index - 1) / (numel(signal) * dt);
end
