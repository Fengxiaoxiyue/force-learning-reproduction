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
