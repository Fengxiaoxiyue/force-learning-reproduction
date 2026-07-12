function metrics = compute_metrics(result)
%COMPUTE_METRICS Compute standard training and testing diagnostics.

metrics = struct();
metrics.training_mae = mean(abs(result.zt - result.ft));
metrics.training_rmse = sqrt(mean((result.zt - result.ft).^2));
metrics.testing_mae = mean(abs(result.zpt - result.ft2));
metrics.testing_rmse = sqrt(mean((result.zpt - result.ft2).^2));
metrics.final_weight_norm = result.wo_len(end);
metrics.max_abs_training_error = max(abs(result.zt - result.ft));
metrics.max_abs_testing_error = max(abs(result.zpt - result.ft2));

if isfield(result, 'elapsed_seconds')
    metrics.elapsed_seconds = result.elapsed_seconds;
end

if all(isfinite(result.zpt)) && std(result.zpt) > 0 && std(result.ft2) > 0
    c = corrcoef(result.zpt(:), result.ft2(:));
    metrics.testing_corr = c(1, 2);
else
    metrics.testing_corr = NaN;
end
end
