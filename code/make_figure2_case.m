function [cfg, info] = make_figure2_case(case_id, fidelity)
%MAKE_FIGURE2_CASE Configuration and targets for Figure 2 examples.
%   Exact waveforms that were not numerically published are deterministic
%   structural reconstructions and are identified in the returned info.

if nargin < 2
    fidelity = 'standard';
end

cfg = make_config('smoke');
cfg.preset = ['figure2_', lower(case_id)];
cfg.tag = cfg.preset;
cfg.makePlots = true;
cfg.saveResults = true;
cfg.verbose = true;
cfg.N = 300;
cfg.nsecs = 360;
cfg.dt = 0.1;
cfg.learn_every = 2;
cfg.seed = 2200 + sum(double(case_id));
cfg.simtime = 0:cfg.dt:(cfg.nsecs - cfg.dt);
cfg.simtime2 = cfg.nsecs:cfg.dt:(2 * cfg.nsecs - cfg.dt);
cfg.num_steps = numel(cfg.simtime);

if strcmpi(fidelity, 'full')
    cfg.N = 1000;
    cfg.nsecs = 1440;
    cfg.simtime = 0:cfg.dt:(cfg.nsecs - cfg.dt);
    cfg.simtime2 = cfg.nsecs:cfg.dt:(2 * cfg.nsecs - cfg.dt);
    cfg.num_steps = numel(cfg.simtime);
end

t = [cfg.simtime, cfg.simtime2];
period = 120;
info = struct('case_id', upper(case_id), 'exact', true, 'note', '');

switch upper(case_id)
    case 'ABC'
        target = triangle_wave(t, period);
        cfg.wo_init_scale = 1.0;
        info.note = 'Triangle-wave training sequence shown in panels A-C.';
    case 'D'
        target = make_four_sine_target(t, cfg);
        info.note = 'Four-sinusoid expression from the supplemental Matlab code.';
    case 'E'
        target = harmonic_target(t, 16, period);
        info.exact = false;
        info.note = 'Deterministic 16-harmonic reconstruction; original coefficients were not published.';
    case 'F'
        clean = make_four_sine_target(t, cfg);
        target = clean;
        info.note = 'Clean test target; Gaussian noise is added only to the training segment.';
    case 'G'
        target = 0.8 * sign(sin(2 * pi * t / period));
        target(target == 0) = 0.8;
        info.exact = false;
        info.note = 'Square-wave reconstruction with the published qualitative form.';
    case 'H'
        target = lorenz_x_target(numel(t), 0.01);
        info.note = 'Lorenz sigma=10, beta=8/3, rho=28; x component divided by 10.';
    case 'I_FAST'
        cfg.nsecs = 120;
        cfg.simtime = 0:cfg.dt:(cfg.nsecs - cfg.dt);
        cfg.simtime2 = cfg.nsecs:cfg.dt:(2 * cfg.nsecs - cfg.dt);
        cfg.num_steps = numel(cfg.simtime);
        t = [cfg.simtime, cfg.simtime2];
        target = sin(2 * pi * t / 6); % 6 tau = 60 ms for tau=10 ms.
        info.note = 'Sine period 60 ms (6 network time constants).';
    case 'I_SLOW'
        cfg.nsecs = 1600;
        cfg.simtime = 0:cfg.dt:(cfg.nsecs - cfg.dt);
        cfg.simtime2 = cfg.nsecs:cfg.dt:(2 * cfg.nsecs - cfg.dt);
        cfg.num_steps = numel(cfg.simtime);
        t = [cfg.simtime, cfg.simtime2];
        target = sin(2 * pi * t / 800); % 800 tau = 8 s.
        info.note = 'Sine period 8 s (800 network time constants).';
    case 'K'
        cfg.amp = 0.05;
        target = cfg.amp * sin(2 * pi * t / period);
        info.note = 'Low-amplitude sine deliberately below chaos-control regime.';
    otherwise
        error('make_figure2_case:unknownCase', 'Unknown Figure 2 case: %s', case_id);
end

split = cfg.num_steps;
cfg.target_test = target(split + 1:2 * split);
if strcmpi(case_id, 'F')
    rng(cfg.seed + 991, 'twister');
    cfg.target_train = target(1:split) + 0.5 * randn(1, split);
else
    cfg.target_train = target(1:split);
end
end

function y = triangle_wave(t, period)
phase = mod(t / period, 1);
y = 1 - 4 * abs(phase - 0.5);
end

function y = harmonic_target(t, count, period)
y = zeros(size(t));
for k = 1:count
    phase = mod(k * 0.73, 1) * 2 * pi;
    y = y + sin(2 * pi * k * t / period + phase) / k^0.75;
end
y = 1.2 * y / max(abs(y));
end

function x_target = lorenz_x_target(count, h)
state = [-8; 8; 27];
x_target = zeros(1, count);
for i = 1:count
    x_target(i) = state(1) / 10;
    k1 = lorenz_rhs(state);
    k2 = lorenz_rhs(state + 0.5 * h * k1);
    k3 = lorenz_rhs(state + 0.5 * h * k2);
    k4 = lorenz_rhs(state + h * k3);
    state = state + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6;
end
end

function d = lorenz_rhs(s)
d = [10 * (s(2) - s(1)); s(1) * (28 - s(3)) - s(2); s(1) * s(2) - (8 / 3) * s(3)];
end
