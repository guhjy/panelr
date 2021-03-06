
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![Travis-CI Build
Status](https://travis-ci.org/jacob-long/panelr.svg?branch=master)](https://travis-ci.org/jacob-long/panelr)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/jacob-long/panelr?branch=master&svg=true)](https://ci.appveyor.com/project/jacob-long/panelr)
[![Coverage
Status](https://img.shields.io/codecov/c/github/jacob-long/panelr/master.svg)](https://codecov.io/github/jacob-long/panelr?branch=master)

# panelr

This is an R package designed to aid in the analysis of panel data,
designs in which the same group of respondents/entities are
contacted/measured multiple times. `panelr` provides some useful
infrastructure, like a `panel_data` object class, as well as automating
some emerging methods for analyses of these data.

It automates the “within-between” (also known as “between-within” and
“hybrid”) specification that combines the desirable aspects of both
fixed effects and random effects econometric models and fits them using
the lme4 package in the backend. Bayesian estimation of these models is
supported by interfacing with the brms package.

## Installation

At the moment, `panelr` is only available through Github. A submission
to CRAN is coming soon.

``` r
install.packages("devtools")
devtools::install_github("jacob-long/panelr")
```

Note the several dependencies: `dplyr`, `tidyr`, `lme4`, `pbkrtest`,
`jtools`, `magrittr`, `stringr`, and `rlang`. You will need `brms` (and
its dependencies, like `rstan`) to do Bayesian estimation.

## Usage

### `panel_data` frames

While not strictly required, the best way to start is to declare your
data as panel data. I’ll load the example data `WageData` to
demonstrate.

``` r
library(panelr)
data("WageData")
colnames(WageData)
```

    #>  [1] "exp"   "wks"   "occ"   "ind"   "south" "smsa"  "ms"    "fem"  
    #>  [9] "union" "ed"    "blk"   "lwage" "t"     "id"

The two key variables here are `t` and `id`. `t` is the wave of the
survey the row of the data refers to while `id` is the survey
respondent. This is a perfectly balanced data set, so there are 7
observations for each of the 595 respondents. We will use those two
pieces of information to create a `panel_data` object.

``` r
wages <- panel_data(WageData, id = id, wave = t)
```

We have to tell `panel_data()` which column refers to the unique
identifiers for respondents/entities (the latter when you have something
like countries or companies instead of people) and which column refers
to the period/wave of data collection. If the waves are not numeric and
indexed starting at 1, the function will attempt to coerce them to that
kind of numbering scheme.

Note that the resulting `panel_data` object will always use the column
names `id` and `wave`, so it will overwrite those columns if they
already exist in the source data. `panel_data` frames are modified
tibbles ([`tibble` package](http://tibble.tidyverse.org/)) that are
grouped by entity.

### `wbm` — the within-between model

Anyone can fit a within-between model without the use of this package as
it is just a particular specification of a multilevel model. With that
said, it’s something that will require some programming and could be
rather prone to error. In the best case, it is cumbersome and
inefficient to create the necessary variables.

`wbm` is the primary function that you’ll use from this package and it
fits within-between models for you, utilizing
[`lme4`](https://cran.r-project.org/web/packages/lme4/index.html) as a
backend.

A three-part model syntax is used that goes like this:

`dv ~ varying_variables | invariant_variables |
cross_level_interactions`

It works like a typical formula otherwise. The bars just tell `panelr`
how to treat the variables. Note also that you can specify random slopes
using `lme4`-style syntax in the third part of the formula as well.

Lagged variables are supported as well through the `lag` function.
Unlike base R, `panelr` lags the variables correctly — wave 1
observations will have NA values for the lagged variable rather than
taking the final wave value of the previous entity.

Here we will specify a model using the `wages` data. We will predict
logged wages (`lwage`) using two time-varying variables — lagged union
membership (`union`) and contemporaneous weeks worked (`wks`) — along
with a time-invariant predictor, a binary indicator for black race
(`blk`). For demonstrative purposes, we’ll fit a random slope for `wks`
and an interaction between `blk` and
`lag(union)`.

``` r
model <- wbm(lwage ~ lag(union) + wks | blk | blk * lag(union) + (wks | id),
             data = wages)
summary(model)
```

    #> MODEL INFO:
    #> Entities: 595
    #> Time periods: 2-7
    #> Dependent variable: lwage
    #> Model type: Linear mixed effects
    #> Specification: within-between
    #> 
    #> MODEL FIT: 
    #> AIC = 1426.48, BIC = 1494.47
    #>  
    #> WITHIN EFFECTS:
    #>            Est. S.E. t val. p      
    #> lag(union) 0.05 0.03 2.01   0.04 * 
    #> wks        0    0    -2.93  0    **
    #> 
    #> Within-entity ICC = 0.73 
    #> 
    #> BETWEEN EFFECTS:
    #>              Est.  S.E. t val. p       
    #> (Intercept)  6.25  0.24 25.93  0    ***
    #> imean(union) 0.03  0.04 0.85   0.4     
    #> imean(wks)   0.01  0.01 2.06   0.04 *  
    #> blk          -0.35 0.06 -5.61  0    ***
    #> 
    #> INTERACTIONS:
    #>                Est.  S.E. t val. p    
    #> lag(union):blk -0.12 0.12 -0.98  0.33 
    #> 
    #> p values calculated using Kenward-Roger df = 592.31 
    #>  
    #> RANDOM EFFECTS:
    #>  Group    Parameter   Std.Dev.
    #>  id       (Intercept) 0.38    
    #>  id       wks         0.01    
    #>  Residual             0.23

Note that `imean` is an internal function that calculates the
individual-level mean, which represents the between-subjects effects of
the time-varying predictors. The within effects are the time-varying
predictors at the occasion level with the individal-level mean
subtracted. If you want the model specified such that the occasion level
predictors do not have the mean subtracted, use the `model =
"contextual"` argument. The “contextual” label refers to the way these
terms are normally interpreted when it is specified that way.

### `widen_panel` and `long_panel`

Two functions that should cover your bases for the tricky business of
**reshaping** panel data are included. Sometimes, like for doing
SEM-based analyses, you need your data in wide format — i.e., one row
per entity. `widen_panel` makes that easy and should require minimal
trial and error or thinking.

Perhaps more often, your raw data are already in wide format and you
need to get it into long format to do cool stuff like use `wbm`. That
can be very tricky, but `long_panel` (I didn’t think `lengthen_panel` or
`longen_panel` quite worked as names) should cover most situations. You
tell it what the labels for periods are (e.g., does it range from `1` to
`5`, `"A"` to `"E"`, or something else?), where they are located (before
or after the variable’s name?), and what kinds of formatting go
before/after it. Unbalanced data are perfectly fine, unlike when trying
to use the already confusing `reshape` function.

## Contributing

I’m happy to receive bug reports, suggestions, questions, and (most of
all) contributions to fix problems and add features. I prefer you use
the Github issues system over trying to reach out to me in other ways.
Pull requests for contributions are encouraged.

Please note that this project is released with a [Contributor Code of
Conduct](CONDUCT.md). By participating in this project you agree to
abide by its terms.

## License

The source code of this package is licensed under the [MIT
License](http://opensource.org/licenses/mit-license.php).
