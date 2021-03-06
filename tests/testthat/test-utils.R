
context("reconstructs")

library(panelr)
w <- panel_data(WageData, id = id, wave = t)

library(dplyr)
test_that("dplyr functions return panel_data objects", {
  expect_s3_class(mutate(w, gender = fem), "panel_data")
  expect_s3_class(transmute(w, gender = fem), "panel_data")
  expect_s3_class(summarize(w, mean_wg = mean(lwage)), "tbl_df")
  expect_s3_class(filter(w, fem == 1), "panel_data")
  expect_s3_class(arrange(w, lwage), "panel_data")
  expect_s3_class(distinct(w, lwage), "tbl_df")
  expect_s3_class(full_join(w, summarize(w, mean_wg = mean(lwage), by = "id")),
                  "panel_data")
  expect_s3_class(inner_join(w, summarize(w, mean_wg = mean(lwage), by = "id")),
                  "panel_data")
  expect_s3_class(left_join(w, summarize(w, mean_wg = mean(lwage), by = "id")),
                  "panel_data")
  expect_s3_class(right_join(w, summarize(w, mean_wg = mean(lwage), by = "id")),
                  "panel_data")
  expect_s3_class(anti_join(w, summarize(w, mean_wg = mean(lwage), by = "id")),
                  "panel_data")
  expect_s3_class(semi_join(w, summarize(w, mean_wg = mean(lwage), by = "id")),
                  "panel_data")
  expect_s3_class(select(w, lwage), "panel_data")
  expect_s3_class(slice(w, 3), "panel_data")
  expect_s3_class(group_by(w, id), "panel_data")
  expect_s3_class(mutate_(w, "gender" = "fem"), "panel_data")
  expect_s3_class(transmute_(w, "gender" = "fem"), "panel_data")
  expect_s3_class(summarize_(w, "mean_wg" = mean(w$lwage)), "tbl_df")
  expect_s3_class(summarise_(w, "mean_wg" = mean(w$lwage)), "tbl_df")
  expect_s3_class(slice_(w, "fem" == 1), "panel_data")
  expect_s3_class(w[names(w)], "panel_data")
})

context("widen_panel")

test_that("widen_panel works", {
  expect_s3_class(widen_panel(w), "data.frame")
})

context("long_panel")

wide <- widen_panel(w)

test_that("long_panel works", {
  expect_s3_class(long_panel(wide, begin = 1, end = 7), "panel_data")
})

wide <- wide[names(wide) %nin% c("occ_3", "lwage_5")]
test_that("long_panel handles unbalanced data", {
  expect_s3_class(long_panel(wide, begin = 1, end = 7), "panel_data")
})

context("tibble printing")

test_that("print.panel_data works", {
  expect_output(print(w))
})

context("extractors")

library(lme4)
mod <- wbm(lwage ~ union, data = w, pvals = FALSE)

test_that("extractors work", {
  expect_silent(getCall(mod))
  expect_silent(predict(mod))
  expect_silent(simulate(mod))
  expect_silent(fixef(mod))
  expect_silent(ranef(mod))
  expect_silent(vcov(mod))
  expect_silent(model.frame(mod))
  expect_silent(nobs(mod))
  expect_silent(formula(mod))
  expect_silent(terms(mod))
  expect_silent(coef(mod))
  expect_silent(anova(mod))
  expect_silent(isGLMM(mod))
  expect_silent(isLMM(mod))
  expect_silent(isNLMM(mod))
})
