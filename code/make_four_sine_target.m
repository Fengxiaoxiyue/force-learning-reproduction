function ft = make_four_sine_target(t, cfg)
%MAKE_FOUR_SINE_TARGET Target from Figure 2D: sum of four sinusoids.
%   The expression follows the supplemental Matlab scripts from Sussillo
%   and Abbott (2009). The first component has angular frequency pi/60,
%   so its period is 120 seconds when cfg.freq = 1/60.

amp = cfg.amp;
freq = cfg.freq;

ft = (amp / 1.0) * sin(1.0 * pi * freq * t) + ...
     (amp / 2.0) * sin(2.0 * pi * freq * t) + ...
     (amp / 6.0) * sin(3.0 * pi * freq * t) + ...
     (amp / 3.0) * sin(4.0 * pi * freq * t);
ft = ft / 1.5;
end
