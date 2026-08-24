# drmeta 0.2.2

This is an update from the CRAN version 0.1.0. Version 0.2.0 substantially
revised the package to implement the design-indexed location-scale
specification described in the accompanying methodological work; versions
0.2.1 and 0.2.2 followed with a behavior fix and a documentation update.

The update adds constrained and unrestricted scale models, location
moderators, observed-support variance-ratio and scale-attenuation summaries,
boundary-aware parametric-bootstrap inference, influence diagnostics for both
the location and scale components, and revised documentation and tests.

## Test environments

- Windows 11 x64, R 4.6.0 (local)
- win-builder, R-devel (2026-08-22 r90443), Windows Server 2022 x64
- win-builder, R-release

## R CMD check results

0 errors | 0 warnings | 1 note

The note reports possibly misspelled words in DESCRIPTION:

    Liang (24:15)
    Viechtbauer (25:57)
    reweights (26:64)

"Liang" and "Viechtbauer" are author surnames in the two cited references.
"reweights" is a standard English verb. All three are spelled correctly.

## Breaking changes from 0.1.0

These are documented in full in NEWS.md.

- Six exported functions have been removed: `dr_variance()`, `dr_weights()`,
  `dr_forest()`, `dr_funnel()`, `dr_plot()`, and `dr_pub_bias()`.
  `dr_variance()` is superseded by `dr_scale_predict()`; study weights are
  available as the `weights` component of a fitted object. The plotting and
  publication-bias functions were withdrawn pending revision against the
  corrected specification.

- `dr_heterogeneity()` no longer returns the design-residual variance
  decomposition or `R2_DR`. That quantity was not identified by the model and
  is superseded by `dr_scale_attenuation()`, which describes the fitted scale
  function and is explicitly not a proportion of heterogeneity explained.

- The pooled effect is returned as `beta`, a named vector of location
  coefficients, rather than as a scalar `mu`.

There are no reverse dependencies.

## Notes

The methodological manuscript cited in the package documentation (Hait, 2026)
is currently an unpublished working paper.

The 0.2.0 software release, which generated the numerical results reported in
that manuscript, is publicly archived on Zenodo at
<doi:10.5281/zenodo.22084325>.
 

