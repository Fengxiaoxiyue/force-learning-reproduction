%RECOVER_FIGURE2_ABC High-cost triangle-sequence recovery attempts.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));

specs(1) = struct('N', 1000, 'seed_offset', 0, 'g', 1.5, 'alpha', 1.0);
specs(2) = struct('N', 1500, 'seed_offset', 0, 'g', 1.5, 'alpha', 1.0);
summary = run_external_recovery('ABC', specs); %#ok<NASGU>
