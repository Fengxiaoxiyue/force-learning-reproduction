function cfg = make_config(preset)
%MAKE_CONFIG Central configuration for FORCE reproduction experiments.
%   cfg = MAKE_CONFIG(preset) returns a struct with model, training, and
%   output settings. Presets keep quick tests separate from the full
%   reproduction run.

if nargin < 1 || isempty(preset)
    preset = 'smoke';
end

thisFile = mfilename('fullpath');
codeDir = fileparts(thisFile);
projectRoot = fileparts(codeDir);

cfg = struct();
cfg.preset = char(preset);
cfg.projectRoot = projectRoot;
cfg.dataDir = fullfile(projectRoot, 'results', 'data');
cfg.figureDir = fullfile(projectRoot, 'results', 'figures');

cfg.seed = 20090718;
cfg.N = 150;
cfg.p = 0.1;
cfg.g = 1.5;
cfg.alpha = 1.0;
cfg.nsecs = 60;
cfg.dt = 0.1;
cfg.learn_every = 2;
cfg.amp = 1.3;
cfg.freq = 1 / 60;
cfg.feedback_scale = 2.0;
cfg.saveResults = true;
cfg.makePlots = true;
cfg.verbose = true;
cfg.tag = cfg.preset;

switch lower(char(preset))
    case 'test'
        cfg.N = 40;
        cfg.nsecs = 6;
        cfg.seed = 101;
        cfg.saveResults = false;
        cfg.makePlots = false;
        cfg.verbose = false;
        cfg.tag = 'test';

    case 'smoke'
        cfg.N = 150;
        cfg.nsecs = 120;
        cfg.seed = 200901;
        cfg.tag = 'smoke_external';

    case 'reproduction'
        cfg.N = 1000;
        cfg.p = 0.1;
        cfg.g = 1.5;
        cfg.alpha = 1.0;
        cfg.nsecs = 1440;
        cfg.dt = 0.1;
        cfg.learn_every = 2;
        cfg.seed = 200902;
        cfg.tag = 'figure2d_external';

    case 'sweep'
        cfg.N = 250;
        cfg.nsecs = 180;
        cfg.seed = 200903;
        cfg.tag = 'sweep_base';

    case 'internal_smoke'
        cfg.N = 120;
        cfg.p = 1.0;
        cfg.nsecs = 120;
        cfg.amp = 0.7;
        cfg.seed = 200904;
        cfg.tag = 'smoke_internal_all2all';

    case 'internal_reproduction'
        cfg.N = 1000;
        cfg.p = 1.0;
        cfg.g = 1.5;
        cfg.alpha = 1.0;
        cfg.nsecs = 1440;
        cfg.dt = 0.1;
        cfg.learn_every = 2;
        cfg.amp = 0.7;
        cfg.seed = 200905;
        cfg.tag = 'figure1c_internal_all2all';

    otherwise
        error('make_config:unknownPreset', 'Unknown preset: %s', preset);
end

cfg.simtime = 0:cfg.dt:(cfg.nsecs - cfg.dt);
cfg.simtime2 = cfg.nsecs:cfg.dt:(2 * cfg.nsecs - cfg.dt);
cfg.num_steps = numel(cfg.simtime);
end
