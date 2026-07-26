function [processed, labels] = preprocess_mocap_motion(path, output_dim)
%PREPROCESS_MOCAP_MOTION Paper-inspired smoothing and interpolation.

if nargin < 2, output_dim = 95; end
[angles_deg, labels] = read_amc_motion(path);
angles_deg = fillmissing(angles_deg, 'linear', 1, 'EndValues', 'nearest');
angles = unwrap(deg2rad(angles_deg), [], 1);
angles = movmean(angles, 5, 1);
old_t = 1:size(angles, 1);
new_t = linspace(1, size(angles, 1), 10 * size(angles, 1));
processed = interp1(old_t, angles, new_t, 'pchip');
processed = processed - mean(processed, 1);

if size(processed, 2) < output_dim
    processed(:, end + 1:output_dim) = 0;
    labels(end + 1:output_dim) = arrayfun(@(i) sprintf('padding_%d', i), ...
        1:(output_dim - numel(labels)), 'UniformOutput', false);
elseif size(processed, 2) > output_dim
    processed = processed(:, 1:output_dim);
    labels = labels(1:output_dim);
end

scale = max(std(processed, 0, 1));
if scale > 0, processed = processed / (3 * scale); end
end
