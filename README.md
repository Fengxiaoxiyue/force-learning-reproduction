# FORCE Learning Reproduction

Independent MATLAB reproduction of the displayed computational cases in Sussillo and Abbott (2009), *Generating Coherent Patterns of Activity from Chaotic Neural Networks*.

## Scope

- Figure 2A--K output family with Figure 1A.
- Figure 2D repeated with Figure 1B and Figure 1C as the agreed architecture benchmark.
- Figures 3--5: PCA, feedback-mixture, and recurrent-gain analyses.
- Figures 6--8: delayed/separate/internal feedback, control-selected outputs, four-bit memory, and motion capture.
- Supplementary Figures S1--S2: non-RLS scalar learning rate and effective eigenvalue spectra.

Exact targets are distinguished from structural reconstructions when the paper does not publish numerical coefficients or waveforms. Scaled failures are retained in the repository and discussed in the report.

## Layout

- `code/`: reusable MATLAB model and analysis functions.
- `scripts/`: one runnable script per paper case group.
- `tests/`: MATLAB unit and smoke integration tests.
- `results/data/`: deterministic MAT files and CSV summaries.
- `results/figures/`: PNG and vector PDF results.
- `data/raw/mocap/`: the two CMU AMC trials named in the paper plus provenance notes.
- `docs/workflow.md`: Chinese teaching-style mathematical and experimental runbook.
- `report/`: LaTeX source and compiled report.

## Run

From the repository root:

```powershell
matlab -batch "run('tests/run_all_tests.m')"
matlab -batch "run('scripts/run_figure2_suite.m')"
matlab -batch "run('scripts/run_figures3_to5.m')"
matlab -batch "run('scripts/run_figures6_to8.m')"
matlab -batch "run('scripts/run_supplement.m')"
```

The reference-scale Figure 2D run remains available separately:

```powershell
matlab -batch "run('scripts/run_reproduction.m')"
```

Compile the report with the installed TeX Live:

```powershell
cd report
latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex
```

## Main Results

- Figure 2D, architecture 1A: testing MAE `0.04033`, correlation `0.99636`.
- Figure 2D, architecture 1C: testing MAE `0.07289`, correlation `0.92645`.
- Figure 6C internal learning: testing MAE `0.00550`.
- Figure 7D four-bit memory: accuracy `98.74%`.
- Figure 8 motion capture: running/walking correlations `0.92024` / `0.96760`.
- Supplement S2: the low-gain network has the larger spectral outlier shift.

See `results/data/*.csv` and the report for every success, partial result, and scaled failure.

## Versioned Milestones

| Commit | Summary |
|---|---|
| `d3be30d` | Reusable external FORCE runner and generalized feedback modes |
| `39155a0` | Figure 2 cases and Figure 2D architecture benchmark |
| `b0c9f56` | Figures 3--5 analyses |
| `7895f5c` | Figures 6--8 controlled-network and motion cases |
| `d4c2527` | Supplementary Figures S1--S2 |

## Sources

The article, publisher supplement, and original example scripts are described in `SOURCES.md`. Bibliographic metadata for the paper was exported from Zotero item `D2YQS7LK` to `report/bibliography/zotero.bib`. CMU motion-capture source and use terms are recorded in `data/raw/mocap/README.md`.
