function metrics = compute_chaos_metrics(result)
%COMPUTE_CHAOS_METRICS Evaluate autonomous chaos without requiring phase lock.

target = double(result.ft2(:));
output = double(result.zpt(:));
assert(numel(target) == numel(output), 'Target and output lengths differ.');
assert(all(isfinite(target)) && all(isfinite(output)), ...
    'Chaos metrics require finite signals.');

target_scale = max(std(target), eps);
horizons = unique(min([100, 500, 1000], numel(target)));
short_mae = zeros(size(horizons));
short_corr = zeros(size(horizons));
for i = 1:numel(horizons)
    count = horizons(i);
    short_mae(i) = mean(abs(output(1:count) - target(1:count)));
    short_corr(i) = signal_corr(output(1:count), target(1:count));
end

sorted_target = sort(target);
sorted_output = sort(output);
quantile_mae = mean(abs(sorted_output - sorted_target));

centered_target = target - mean(target);
centered_output = output - mean(output);
target_power = abs(fft(centered_target)).^2;
output_power = abs(fft(centered_output)).^2;
half_count = max(2, floor(numel(target) / 2));
log_target_power = log(target_power(2:half_count) + eps);
log_output_power = log(output_power(2:half_count) + eps);

max_lag = min(500, numel(target) - 1);
target_acf = normalized_acf(centered_target, max_lag);
output_acf = normalized_acf(centered_output, max_lag);

metrics = struct();
metrics.horizon_steps = horizons;
metrics.short_horizon_mae = short_mae;
metrics.short_horizon_corr = short_corr;
metrics.quantile_mae = quantile_mae;
metrics.normalized_quantile_mae = quantile_mae / target_scale;
metrics.mean_error = abs(mean(output) - mean(target));
metrics.std_ratio = std(output) / target_scale;
metrics.log_psd_corr = signal_corr(log_output_power, log_target_power);
metrics.autocorrelation_mae = mean(abs(output_acf - target_acf));
metrics.pointwise_mae = mean(abs(output - target));
metrics.pointwise_corr = signal_corr(output, target);
end

function values = normalized_acf(signal, max_lag)
denominator = sum(signal.^2);
values = zeros(max_lag + 1, 1);
if denominator <= eps
    return;
end
for lag = 0:max_lag
    values(lag + 1) = signal(1:end-lag)' * signal(1+lag:end) / denominator;
end
end

function value = signal_corr(a, b)
if std(a) <= eps || std(b) <= eps
    value = double(all(abs(a - b) <= eps));
    return;
end
matrix = corrcoef(a, b);
value = matrix(1, 2);
end
