%RECOVER_FIGURE2_I High-cost fast and slow timescale attempts.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));

fast(1) = spec(1000, 1.5, 1, 1);
fast(2) = spec(1500, 1.5, 1, 1);
fast(3) = spec(1500, 1.5, 10, 2);
fast(4) = spec(1000, 1.2, 1, 2);
fast(5) = spec(1000, 1.2, 10, 2);
fast(6) = spec(1000, 1.0, 1, 2);
fast(7) = spec(1000, 1.0, 10, 2);
run_external_recovery('I_FAST', fast);

slow(1) = spec(1000, 1.5, 1, 3);
slow(2) = spec(1000, 1.5, 10, 3);
slow(3) = spec(1500, 1.5, 1, 3);
slow(4) = spec(2000, 1.5, 1, 3);
run_external_recovery('I_SLOW', slow);

function value = spec(N, g, alpha, durationScale)
value = struct('N', N, 'seed_offset', 0, 'g', g, 'alpha', alpha, ...
    'duration_scale', durationScale);
end
