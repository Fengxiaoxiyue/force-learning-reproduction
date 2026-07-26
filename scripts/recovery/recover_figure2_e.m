%RECOVER_FIGURE2_E High-cost 16-component structural target attempts.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));

specs(1) = struct('N', 1000, 'seed_offset', 0, 'g', 1.5, 'alpha', 1.0);
specs(2) = struct('N', 1500, 'seed_offset', 0, 'g', 1.5, 'alpha', 1.0);
specs(3) = struct('N', 1500, 'seed_offset', 0, 'g', 1.8, 'alpha', 1.0);
specs(4) = struct('N', 1500, 'seed_offset', 0, 'g', 1.5, 'alpha', 10.0);
specs(5) = struct('N', 2000, 'seed_offset', 0, 'g', 1.5, 'alpha', 10.0);
summary = run_external_recovery('E', specs); %#ok<NASGU>
