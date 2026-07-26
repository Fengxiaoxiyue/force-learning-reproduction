%RUN_FIGURES3_TO5 PCA, feedback-mixture, and recurrent-gain analyses.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'code'));

[cfg, ~] = make_figure2_case('D', 'standard');
cfg.N = 500;
cfg.nsecs = 720;
cfg.simtime = 0:cfg.dt:(cfg.nsecs - cfg.dt);
cfg.simtime2 = cfg.nsecs:cfg.dt:(2 * cfg.nsecs - cfg.dt);
cfg.num_steps = numel(cfg.simtime);
cfg.target_train = make_four_sine_target(cfg.simtime, cfg);
cfg.target_test = make_four_sine_target(cfg.simtime2, cfg);
cfg.tag = 'figure3_source';
analysis3 = analyze_figure3_pca(cfg); %#ok<NASGU>
summary4 = run_figure4_feedback_sweep(); %#ok<NASGU>
summary5 = run_figure5_gain_sweep(); %#ok<NASGU>

fprintf('Figures 3-5 analyses complete.\n');
