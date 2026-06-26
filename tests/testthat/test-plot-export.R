test_that("plot_filename sanea el nombre y añade la fecha", {
  expect_equal(plot_filename("Barras", "png", as.Date("2026-06-26")), "barras_2026-06-26.png")
  expect_equal(plot_filename("Coincidencia kappa!", "pdf", as.Date("2026-01-02")),
               "coincidencia_kappa_2026-01-02.pdf")
  expect_equal(plot_filename("", "png", as.Date("2026-06-26")), "grafico_2026-06-26.png")
})

test_that("dt_with_buttons añade B al dom y los botones, conservando opciones", {
  o <- dt_with_buttons(list(dom = "tip", pageLength = 25))
  expect_equal(o$dom, "Btip")
  expect_equal(o$pageLength, 25)
  expect_equal(length(o$buttons), 3)
  expect_equal(o$buttons[[2]]$extend, "csv")
  expect_equal(o$buttons[[2]]$exportOptions$modifier$page, "all")
  expect_equal(dt_with_buttons(list())$dom, "Blfrtip")   # sin dom previo
  expect_equal(dt_with_buttons(list(dom = "Bt"))$dom, "Bt")  # no duplica B
})
