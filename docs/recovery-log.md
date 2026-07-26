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
