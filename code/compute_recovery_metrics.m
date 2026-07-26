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
cross_spectrum = fft(segment_output) .* conj(fft(segment_target));
[~, peak_index] = max(real(ifft(cross_spectrum)));
lag = peak_index - 1;
candidate_a = circshift(segment_output, -lag);
candidate_b = circshift(segment_output, lag);
if mean(abs(candidate_b - segment_target)) < mean(abs(candidate_a - segment_target))
    aligned = candidate_b;
    lag = -lag;
else
    aligned = candidate_a;
end
metrics.phase_lag_steps = lag;
metrics.phase_aligned_mae = mean(abs(aligned - segment_target));
if std(aligned) > eps && std(segment_target) > eps
    corr_matrix = corrcoef(aligned, segment_target);
    metrics.phase_aligned_corr = corr_matrix(1, 2);
else
    metrics.phase_aligned_corr = double(max(abs(aligned - segment_target)) < 1e-10);
end

metrics.output_dominant_frequency = dominant_frequency(output, result.cfg.dt);
metrics.target_dominant_frequency = dominant_frequency(target, result.cfg.dt);
metrics.frequency_ratio = metrics.output_dominant_frequency / ...
    max(metrics.target_dominant_frequency, eps);
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
