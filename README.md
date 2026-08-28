# drmeta

**Design-Indexed Location-Scale Meta-Analysis**

`drmeta` fits constrained and unrestricted meta-analytic location-scale models
in which residual between-study heterogeneity is modeled as an exponential
function of a prespecified design-robustness index:

```text
y_i ~ N(x_i'beta, v_i + tau0^2 * exp(-gamma * DR_i))
```

The constrained model imposes `gamma >= 0`, representing the directional
hypothesis that unexplained between-study heterogeneity does not increase as
design robustness improves. Setting `gamma = 0` recovers the conventional
random-effects model exactly.

The package supports maximum-likelihood (ML) and restricted maximum-likelihood
(REML) estimation, location moderators, constrained and unrestricted scale
models, prediction of design-indexed heterogeneity, observed-support scale
contrasts, leave-one-out influence diagnostics, and parametric-bootstrap
inference for the scale gradient.

## Installation

Install the stable release from CRAN:

```r
install.packages("drmeta")
library(drmeta)
```

The current CRAN release is version **0.2.2**.

To install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("causalfragility-lab/drmeta")
```

For an exact versioned GitHub installation:

```r
remotes::install_github(
  "causalfragility-lab/drmeta",
  ref = "v0.2.2"
)
```

## Quick start

```r
library(drmeta)

bcg <- utils::read.csv(
  system.file(
    "extdata",
    "bcg_design_robustness.csv",
    package = "drmeta"
  )
)

# Constrained design-indexed scale model
fit <- drmeta(
  yi = bcg[["yi"]],
  vi = bcg[["vi"]],
  dr = bcg[["dr"]]
)

summary(fit)
```

## Minimum comparison set

A design-indexed scale analysis should generally be interpreted alongside
conventional random effects and an unrestricted scale model.

```r
# Conventional random effects: gamma fixed at 0
re <- drmeta(
  yi = bcg[["yi"]],
  vi = bcg[["vi"]],
  dr = bcg[["dr"]],
  gamma_fixed = 0
)

# Constrained directional scale model
dr <- drmeta(
  yi = bcg[["yi"]],
  vi = bcg[["vi"]],
  dr = bcg[["dr"]]
)

# Unrestricted scale model
ls <- drmeta(
  yi = bcg[["yi"]],
  vi = bcg[["vi"]],
  dr = bcg[["dr"]],
  constrained = FALSE
)

# Joint location-scale model
jls <- drmeta(
  yi = bcg[["yi"]],
  vi = bcg[["vi"]],
  dr = bcg[["dr"]],
  mods = 1 - bcg[["dr"]]
)
```

## Interpretation over observed support

The fitted variance function is

```text
tau^2(DR) = tau0^2 * exp(-gamma * DR).
```

Because values outside the observed range of the design index are
extrapolations, interpretation should ordinarily focus on the observed support
of `DR`.

```r
# Proportional attenuation over the observed DR range
dr_scale_attenuation(fit)

# Predicted residual heterogeneity over observed support
dr_scale_predict(fit)

# Plot the fitted variance function
dr_plot_vfun(fit)

# Classical and design-indexed heterogeneity summaries
dr_heterogeneity(fit)
```

The magnitude of `gamma` depends on the scaling of the design index and should
not be interpreted in isolation. Report it together with the observed DR
range and a fitted variance ratio or attenuation contrast over a scientifically
meaningful interval.

## Boundary-aware inference

Under the constrained model, the null hypothesis `gamma = 0` lies on the
boundary of the parameter space. Standard chi-square likelihood-ratio
references therefore do not generally apply.

`drmeta` provides a parametric-bootstrap procedure for the positive scale
gradient:

```r
drmeta_bootstrap_gamma(
  fit,
  B = 999,
  seed = 1
)
```

If the constrained estimate is already at `gamma = 0`, the function
short-circuits and returns `p.value = 1`, because the fitted alternative and
null coincide at the boundary. In that situation, an unrestricted scale fit
can help determine whether the best-fitting gradient instead points in the
opposite direction.

```r
ls <- drmeta(
  yi = bcg[["yi"]],
  vi = bcg[["vi"]],
  dr = bcg[["dr"]],
  constrained = FALSE
)

summary(ls)
```

## Leave-one-out diagnostics

Location and scale influence can differ. A study may have little influence on
the pooled location while materially affecting the estimated heterogeneity
gradient.

```r
dr_loo(fit)
```

The output reports leave-one-out changes in the location estimate,
`tau0sq`, and `gamma`, together with convergence information.

## What this model does and does not do

A design-indexed scale model changes how residual heterogeneity and therefore
precision vary across studies. It does **not** identify or remove a systematic
design-linked shift in the conditional mean.

If the mean varies with design robustness, a scale-only pooled estimate is a
model-dependent weighted average rather than the effect of a hypothetical
perfectly designed study.

When design-linked mean differences are scientifically plausible, include
appropriate location moderators through `mods` and compare the scale-only
model with a joint location-scale specification.

Scale reweighting should not be described as confounding adjustment or bias
correction.

## Constructing a design-robustness score

For confirmatory use, the design index should be specified independently of
the realized meta-analytic result.

In particular, a primary design score should not use:

- the realized effect estimate,
- its standard error,
- its p-value,
- its confidence interval, or
- any other outcome-dependent diagnostic.

Scores incorporating such information are better treated as exploratory.

The package provides tools for constructing and checking design indices:

```r
dr_score(
  balance = c(0.9, 0.6, 0.4),
  overlap = c(0.8, 0.7, 0.5),
  weights = c(2, 1)
)

normalize_01(c(2, 5, 8))
```

`dr_from_design()` is provided as a convenience for illustrative design-type
mappings. Its defaults are demonstrations, not a validated universal hierarchy
of study quality.

## Reporting

A primary analysis should report:

1. the construction and scaling of the design-robustness index;
2. its observed range and number of distinct values;
3. the fitted `gamma`, convergence status, and boundary status;
4. a variance ratio or attenuation contrast over observed support;
5. conventional random effects;
6. the constrained DR-Meta fit;
7. an unrestricted scale fit; and
8. a location model when design-linked mean differences are plausible.

A large `gamma` near the optimization limit should prompt a wider-bound
sensitivity analysis rather than being interpreted mechanically.

## Software citation

The stable CRAN release is:

**drmeta 0.2.2 — Design-Indexed Location-Scale Meta-Analysis**

DOI: **10.32614/CRAN.package.drmeta**

Canonical CRAN page:

```text
https://CRAN.R-project.org/package=drmeta
```

Source repository:

```text
https://github.com/causalfragility-lab/drmeta
```

Versioned GitHub release:

```text
https://github.com/causalfragility-lab/drmeta/releases/tag/v0.2.2
```

## Status

Current stable version: **0.2.2**

`NEWS.md` documents changes across releases, including:

- the design-indexed location-scale specification introduced in version 0.2.0;
- removal of the design-explained variance decomposition;
- the version 0.2.1 boundary short-circuit in
  `drmeta_bootstrap_gamma()`; and
- documentation and archival updates in version 0.2.2.

## License

MIT
