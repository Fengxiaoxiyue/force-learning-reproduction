%RUN_FIGURES6_TO8 Feedback variants, controlled tasks, and motion capture.

projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'code'));

% Figure 6A: delayed and distorted output feedback in Figure 1A.
[cfg6a,~]=make_figure2_case('D','full');
cfg6a.tag='figure6a_delayed_nonlinear';
cfg6a.feedback_mode='delayed_nonlinear';
cfg6a.feedback_delay_steps=round(10/cfg6a.dt); % 100 ms = 10 tau.
result6a=run_force_external(cfg6a); %#ok<NASGU>

% Figure 6B: scaled separate feedback network, Figure 1B.
[cfg6b,~]=make_figure2_case('D','standard');
cfg6b.N=500; cfg6b.NF=95; cfg6b.nsecs=720;
cfg6b.simtime=0:cfg6b.dt:(cfg6b.nsecs-cfg6b.dt);
cfg6b.simtime2=cfg6b.nsecs:cfg6b.dt:(2*cfg6b.nsecs-cfg6b.dt);
cfg6b.num_steps=numel(cfg6b.simtime);
cfg6b.target_train=make_four_sine_target(cfg6b.simtime,cfg6b);
cfg6b.target_test=make_four_sine_target(cfg6b.simtime2,cfg6b);
cfg6b.tag='figure6b_feedback_network';
result6b=run_force_feedback_network(cfg6b); %#ok<NASGU>

% Figure 6C: internal FORCE learning, Figure 1C.
[cfg6c,~]=make_figure2_case('D','full');
cfg6c.N=750; cfg6c.p=0.5; cfg6c.amp=0.7; cfg6c.tag='figure6c_internal';
cfg6c.target_train=make_four_sine_target(cfg6c.simtime,cfg6c);
cfg6c.target_test=make_four_sine_target(cfg6c.simtime2,cfg6c);
result6c=run_force_internal_all2all(cfg6c); %#ok<NASGU>

cfg7=make_config('smoke'); cfg7.N=300; cfg7.alpha=5; cfg7.g=1.5;
result7b=run_figure7_multifunction(cfg7); %#ok<NASGU>
cfg7d=cfg7; cfg7d.N=400; cfg7d.g=1.0; cfg7d.alpha=40;
result7d=run_figure7_memory(cfg7d); %#ok<NASGU>

cfg8=make_config('smoke'); cfg8.N=400; cfg8.NF=95; cfg8.p=0.05; cfg8.alpha=2;
run_path=fullfile(projectRoot,'data','raw','mocap','09_02.amc');
walk_path=fullfile(projectRoot,'data','raw','mocap','08_01.amc');
result8=run_figure8_mocap(cfg8,run_path,walk_path); %#ok<NASGU>

case_id={'6A';'6B';'6C';'7B';'7D';'8-run';'8-walk'};
architecture={'1A-delayed';'1B';'1C';'1C';'1C';'1B';'1B'};
metric_name={'testing_mae';'testing_mae';'testing_mae';'mean_mae';'bit_accuracy';'correlation';'correlation'};
metric_value=[result6a.metrics.testing_mae; result6b.metrics.testing_mae; ...
    result6c.metrics.testing_mae; mean(result7b.mae); result7d.accuracy; ...
    result8.metrics(1,2); result8.metrics(2,2)];
summary=table(case_id,architecture,metric_name,metric_value);
writetable(summary,fullfile(projectRoot,'results','data','figures6_to8_summary.csv'));

fprintf('Figures 6-8 experiments complete.\n');
