function [w, P, dw, info] = rls_update(w, P, r, e)
%RLS_UPDATE One recursive least-squares update used by FORCE learning.
%   w is the current readout vector, P is the inverse correlation matrix,
%   r is the firing-rate vector, and e = z - f is the instantaneous error.

k = P * r;
rPr = r' * k;
c = 1.0 / (1.0 + rPr);
P = P - k * (k' * c);
dw = -e * k * c;
w = w + dw;

if nargout > 3
    info = struct();
    info.rPr = rPr;
    info.c = c;
    info.dw_norm = sqrt(dw' * dw);
end
end
