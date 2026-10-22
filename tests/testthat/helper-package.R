local_package <- function(
  path = NULL,
  name = "templatepackage",
  env = caller_env()
) {
  if (is.null(path)) {
    path <- withr::local_tempdir(.local_envir = env)
    desc <- desc::desc("!new")
    desc$set("Package", name)
    desc$set("Title", "A test template package")
    desc$write(file = file.path(path, "DESCRIPTION"))
  }

  pkgload::load_all(path, quiet = TRUE)
  defer(pkgload::unload(name), envir = env)

  path
}

local_installed_package <- function(name, on_load, env = caller_env()) {
  src <- withr::local_tempdir(.local_envir = env)
  lib <- withr::local_tempdir(.local_envir = env)

  path <- file.path(src, name)
  dir.create(file.path(path, "R"), recursive = TRUE)
  writeLines(
    c(
      paste0("Package: ", name),
      "Title: A Test Package",
      "Version: 0.0.1",
      "Description: A test package.",
      "License: MIT",
      "Authors@R: person('A', 'B', email = 'a@b.c', role = c('aut', 'cre'))"
    ),
    file.path(path, "DESCRIPTION")
  )
  writeLines("", file.path(path, "NAMESPACE"))
  writeLines(on_load, file.path(path, "R", "zzz.R"))

  out <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", "--no-test-load", "-l", shQuote(lib), shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!is.null(attr(out, "status"))) {
    abort(c("Can't install test package.", out))
  }

  withr::local_libpaths(lib, action = "prefix", .local_envir = env)
  defer(
    if (isNamespaceLoaded(name)) unloadNamespace(name),
    envir = env
  )

  lib
}
