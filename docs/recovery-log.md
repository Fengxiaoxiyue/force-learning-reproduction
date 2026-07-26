# High-Cost Recovery Log

This log records local-only recovery attempts for cases that were partial or
failed in the first scaled reproduction. Raw attempts are stored under
`results/recovery/`; they do not overwrite the original baseline artifacts.

## Evaluation Rules

- Report exact test MAE and correlation first.
- For periodic targets, also report one-cycle phase-aligned MAE/correlation,
  amplitude ratio, and dominant-frequency ratio.
- Keep failed attempts and fixed seeds; do not select only favorable runs.
- Mark targets with unpublished coefficients or waveforms as structural.
- Commit each paper case separately after its attempts and diagnosis finish.

## Baseline Cases to Revisit

| Case | Baseline issue | Recovery direction |
|---|---|---|
| Figure 2A-C | triangle correlation 0.833 | increase N to paper scale |
| Figure 2E | 16-component output unstable | increase N; target remains structural |
| Figure 2F | noisy-target correlation 0.612 | increase N and diagnose denoising |
| Figure 2I fast/slow | timescale limits | increase N and training cycles |
| Figure 2J | one-shot correlation 0.827 | increase N and repeated trials |
| Figure 2H | long pointwise divergence | add chaotic short-horizon/distribution metrics |
| Figure 2D / 6B | scaled Figure 1B unstable | increase generator and feedback sizes |
| Figure 6A | delayed nonlinear loop unstable | tune published loop parameters |
| Figure 7B | five-pattern MAE 0.519 | use paper N and alpha |
| Supplement S1 | frozen output drifts | sparse high-N non-RLS run |

## Attempt Records

Entries are appended case by case with configuration, cost, outcome, and the
most likely reason for success or failure.

### Figure 2A-C: triangle sequence

| N | Train MAE | Test MAE | Test corr. | Phase-aligned MAE | Runtime |
|---:|---:|---:|---:|---:|---:|
| 1000 | 0.00758 | 0.28888 | 0.83285 | 0.03563 | 20.9 s |
| 1500 | 0.00336 | 0.00260 | 0.99998 | 0.00154 | 52.2 s |

**Outcome: recovered.** At `N=1000`, the amplitude ratio (0.996) and dominant
frequency ratio (1.000) show that the correct autonomous orbit was learned,
but its absolute phase drifted. Increasing the network to `N=1500` removed
the phase error without changing the seed, gain, regularization, target, or
training duration. The failure was therefore capacity/closed-loop phase
stability, not an incorrect target or RLS implementation.

### Figure 2E: 16-component structural target

| N | g | alpha | Test MAE | Early aligned corr. | Late aligned corr. | Runtime |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 1.5 | 1 | 0.547 | 0.552 | 0.896 | 20.0 s |
| 1500 | 1.5 | 1 | 0.483 | 0.707 | 0.539 | 52.0 s |
| 1500 | 1.8 | 1 | 0.630 | 0.308 | 0.585 | 50.6 s |
| 1500 | 1.5 | 10 | 0.445 | 0.997 | 0.706 | 51.4 s |
| 2000 | 1.5 | 10 | 0.379 | 0.970 | 0.781 | 91.5 s |

**Outcome: not recovered.** Stronger regularization produced a very accurate
first test cycle, but the frozen trajectory drifted and later cycles degraded.
Increasing `N` to 2000 improved exact MAE only modestly; increasing `g` to 1.8
made the result worse. Low training error together with poor late-cycle error
identifies closed-loop trajectory instability rather than an RLS convergence
failure. The original 16 coefficients were not published, so this deterministic
high-harmonic reconstruction may also be harder or spectrally different from
the paper target. This result cannot test exact numerical replication of 2E.

### Figure 2F: learning a noisy target

| N | alpha | Duration | Test MAE | Early aligned MAE | Late aligned MAE | Runtime |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 1 | 1440 | 0.419 | 0.0669 | 0.0579 | 21.2 s |
| 1500 | 1 | 1440 | 0.964 | 0.0899 | 0.0998 | 52.0 s |
| 1500 | 10 | 1440 | 0.318 | 0.0586 | 0.0674 | 52.0 s |
| 2000 | 10 | 1440 | 0.785 | 0.3548 | 0.4829 | 91.7 s |
| 1500 | 10 | 2880 | 0.326 | 0.0425 | 0.0422 | 101.7 s |

**Outcome: waveform and denoising recovered; absolute phase only partial.**
The `N=1500`, `alpha=10`, double-duration run generated a clean autonomous
four-sine waveform despite training against additive Gaussian noise. Its early
and late one-cycle correlations were 0.9974 and 0.9980, amplitude ratio was
0.996, and frequency ratio was 1.000. The remaining exact MAE comes from a
nearly constant/global phase offset: doubling training reduced aligned error
but left the lag drift near 1040 samples. Increasing `N` to 2000 degraded the
orbit, showing that capacity alone is not monotonic for a fixed random draw.
The training MAE near 0.41 is expected because it is measured against the
noisy target and is therefore not evidence of failed denoising.

### Figure 2I: fast and slow timescales

Fast target (period 6 network time constants):

| N | g | alpha | Duration | Test MAE | Test corr. | Frequency ratio |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 1.5 | 1 | 120 | 0.222 | 0.941 | 1.000 |
| 1500 | 1.5 | 1 | 120 | 0.556 | 0.417 | 0.950 |
| 1500 | 1.5 | 10 | 240 | 0.546 | 0.428 | 0.975 |
| 1000 | 1.2 | 1 | 240 | 0.064 | 0.992 | 1.000 |
| 1000 | 1.0 | 1 | 240 | 0.231 | 0.917 | 1.000 |

**Fast outcome: recovered.** Lowering `g` from 1.5 to 1.2 and training for
40 cycles preserved unit amplitude and the correct frequency throughout the
autonomous test. Larger `N` did not help. The limiting factor was excessive
chaotic gain relative to the six-time-constant oscillation, not capacity.

Slow target (period 800 network time constants):

| N | alpha | Training cycles | Train MAE | Test MAE | Frequency ratio | Runtime |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 1 | 6 | 0.0209 | 1.550 | 0.167 | 66.4 s |
| 1000 | 10 | 6 | 0.0353 | 1.262 | 0.167 | 69.3 s |
| 1500 | 1 | 6 | 0.0154 | 0.777 | 1.333 | 166.6 s |
| 2000 | 1 | 6 | 0.0016 | 0.851 | 2.333 | 304.6 s |

**Slow outcome: not recovered.** Increasing the baseline from two to six
training cycles and scaling to `N=2000` drove online error as low as 0.0016,
but the frozen loop selected the wrong autonomous frequency. `N=1500` was the
best compromise, restoring amplitude ratio to 0.957, yet oscillating 1.333
times too fast. The non-monotonic frequency changes with `N` indicate a
closed-loop bifurcation/stability problem. More samples alone are unlikely to
fix it; recovery would require a targeted search over gain, feedback scale,
seed, or an explicit slow-state regularizer.

### Figure 2J: one-shot learning with two feedback loops

| N | Training trials | Train MAE | Test MAE | Test corr. | Runtime |
|---:|---:|---:|---:|---:|---:|
| 300 | 12 | 0.01239 | 0.06165 | 0.97768 | 2.8 s |
| 500 | 24 | 0.00076 | 0.00089 | 0.999996 | 22.0 s |

**Outcome: structural case recovered.** The original implementation paired a
readout error computed from the old recurrent state with an RLS regressor from
the newly integrated state. Correcting that one-step mismatch improved the
original-size test correlation from 0.827 to 0.978. Increasing to `N=500` and
24 repeated initialization/sequence trials then produced a stable autonomous
trace with effectively exact agreement. The main failure was implementation
timing, with capacity and repeated trials providing the final improvement.
Because the paper did not publish the numerical aperiodic waveform, this
validates the two-loop one-shot mechanism but not pointwise replication of the
paper's particular target.

### Figure 2H: Lorenz chaotic output

| N | Pointwise corr. | First-100 corr. | Quantile MAE / target SD | SD ratio | Log-PSD corr. | ACF MAE |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 0.046 | 0.887 | 0.098 | 0.983 | 0.973 | 0.0570 |
| 1500 | -0.014 | 0.201 | 0.085 | 0.981 | 0.968 | 0.0302 |

**Outcome: statistically recovered.** Both autonomous outputs lose pointwise
alignment over the full test, as expected after small state errors grow on a
chaotic attractor. The `N=1000` run retains strong short-horizon agreement and
matches the target distribution and spectrum. `N=1500` halves training error
and improves the marginal distribution and autocorrelation, but diverges in
phase earlier. This non-monotonic short-horizon behavior is expected for a
single deterministic seed near a chaotic trajectory and is not evidence that
the larger network lost the attractor. Long-horizon pointwise MAE remains in
the artifact for transparency but is not the reproduction success criterion.

### Figure 1B / Figure 6B: separate feedback network

| N | Inputs / feedback unit | Readout inputs | Train MAE | Test MAE | Early/late aligned corr. | Frequency ratio |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 25 | 25 | 0.487 | 0.667 | 0.604 / 0.362 | 0.833 |
| 1000 | 25 | 1000 | 0.047 | 1.007 | 0.505 / 0.568 | 0.917 |
| 1000 | 100 | 1000 | 0.032 | 0.952 | 0.461 / 0.376 | 0.750 |
| 1500 | 100 | 1500 | 0.021 | 0.829 | 0.388 / 0.470 | 2.250 |

**Outcome: not recovered at the feasible scale.** The implementation audit
corrected two deviations from the published Figure 6B setup: trainable `JFG`
connections now start with random nonzero weights, and readout sparsity `pz`
is implemented explicitly. At `N=1000`, the paper's `pz=pFG=0.025` leaves
only 25 samples per readout/feedback unit and cannot fit online. A dense
readout restores low training error, and increasing feedback sampling to 100
inputs improves it further, but no frozen trajectory has the target waveform.
The `N=1500` run also selects the wrong frequency. The paper used `N=20000`,
95 feedback neurons, and 500 generator inputs per feedback neuron; the present
largest run has 13 times fewer generator neurons and one fifth as many samples
per feedback unit. The remaining failure is consistent with the random-sampling
capacity argument given for Figure 6B, not a scalar-error or phase-offset bug.

### Figure 6A: delayed nonlinear feedback

| N | Delay | Gain | Train MAE | Test MAE | Early/late aligned corr. | Frequency ratio |
|---:|---:|---:|---:|---:|---:|---:|
| 1000 | 50 ms | 1.3 | 0.096 | 1.181 | 0.407 / 0.506 | 0.833 |
| 1000 | 100 ms | 1.0 | 0.061 | 0.956 | 0.458 / 0.332 | 0.750 |
| 1000 | 100 ms | 1.3 | 0.093 | 1.388 | 0.442 / 0.518 | 0.500 |
| 1000 | 100 ms | 1.6 | 0.157 | 1.847 | 0.578 / 0.516 | 0.167 |
| 1000 | 150 ms | 1.3 | 0.082 | 1.006 | 0.261 / 0.556 | 0.583 |
| 1500 | 100 ms | 1.3 | 0.047 | 0.949 | 0.649 / 0.383 | 0.333 |

**Outcome: not recovered.** The test path previously cleared its delay buffer
at the training/test boundary. It now carries the final 100 ms of training
output into testing, matching a continuous delayed system, and a regression
test protects that behavior. Nevertheless, the published point
`1.3*tanh(sin(pi*z(t-100 ms)))` selects a wrong-frequency autonomous orbit.
Sweeping delay and gain found no stable target orbit; stronger nonlinear gain
was actively harmful. Increasing to `N=1500` halved online error without
stabilizing the frozen loop. The remaining failure is a delayed closed-loop
stability/parameter-basin issue rather than a history-reset artifact.
