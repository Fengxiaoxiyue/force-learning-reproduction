# FORCE Learning Reproduction

This repository reproduces a compact part of Sussillo and Abbott (2009), focusing on Figure 2D with the Figure 1A external feedback architecture. It also includes a small Figure 1C all-to-all internal-learning extension.

## Project layout

- `code/`: reusable MATLAB functions for the model, target function, RLS update, metrics, and plotting.
- `scripts/`: runnable experiment scripts.
- `tests/`: lightweight MATLAB tests.
- `results/data/`: generated `.mat` and `.csv` outputs.
- `results/figures/`: generated plots.
- `docs/workflow.md`: step-by-step reproduction notes in Chinese.
- `report/`: LaTeX project report.
- `SOURCES.md`: paper citation and instructions for retrieving excluded source materials.

## Commands

Run from the project root:

```matlab
matlab -batch "run('tests/run_all_tests.m')"
matlab -batch "run('scripts/run_smoke.m')"
matlab -batch "run('scripts/run_sweep.m')"
matlab -batch "run('scripts/run_internal_all2all.m')"
matlab -batch "run('scripts/run_reproduction.m')"
```

The full reproduction uses `N=1000` and `nsecs=1440`, matching the scale of the supplemental MATLAB script. Start with tests and smoke runs before launching the full run.

## Reproduction target

The main target is the Figure 2D periodic output, a sum of four sinusoids. The MATLAB expression is adapted from the supplemental script `force_external_feedback_loop.m`.

The external feedback model trains only the readout vector `w` with recursive least squares. The recurrent matrix and feedback weights remain fixed. This corresponds to the Figure 1A architecture in the paper.

The completed full reproduction generated:

- `results/data/figure2d_external.mat`
- `results/figures/figure2d_external_traces.png`
- `report/figures/force-traces.pdf` for direct LaTeX/Overleaf inclusion
- Training MAE: `0.005416`
- Testing MAE: `0.036433`
- Testing correlation: `0.997139`

The parameter sweep table is saved at `results/data/sweep_summary.csv`.

## Notes

MATLAB R2025a is available on this machine. In the Codex sandbox, `matlab -batch` may require running outside the sandbox because MATLAB needs access to its normal startup/configuration files.

The LaTeX report source is in `report/`. This environment does not currently have TeX Live or a complete Tectonic cache, so local PDF compilation failed at the TeX runtime level. The source is structured for Overleaf upload and includes the generated Figure 2D plot when `results/figures/figure2d_external_traces.pdf` is available.

## Source materials

The paper PDF, publisher supplemental files, and course template are excluded from Git history. See `SOURCES.md` for the paper citation and retrieval guidance.
