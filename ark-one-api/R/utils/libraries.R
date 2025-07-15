# Necessary packages
required_packages <- c(
  "plumber", "jose", "digest", "data.table", "DBI", "RPostgres",
  "qcc", "e1071", "forecast", "isotree", "dbscan", "future",
  "parallel", "jsonlite", "ggplot2", "dplyr", "grid", "magrittr",
  "pool", "bcrypt", "uuid", "testthat", "httr", "callr", "httpuv", "later"
)

# Função para ler pacotes do renv.lock (ajustado para caminho relativo ao projeto)
get_lockfile_packages <- function(lockfile = file.path("..", "..", "renv.lock")) {
  if (!file.exists(lockfile)) return(character(0))
  lock <- jsonlite::fromJSON(lockfile)
  if (!"Packages" %in% names(lock)) return(character(0))
  return(names(lock$Packages))
}

# Helper to check if a package is base/recommended (not managed by renv)
is_base_or_recommended <- function(pkg) {
  pkg %in% rownames(installed.packages(priority = c("base", "recommended")))
}

# Split required packages into those managed by renv and those not
renv_managed_packages <- required_packages[!vapply(required_packages, is_base_or_recommended, logical(1))]
base_or_recommended_packages <- setdiff(required_packages, renv_managed_packages)

lockfile_packages <- get_lockfile_packages()

# Check which renv-managed packages are missing from lockfile
missing_in_lockfile <- setdiff(renv_managed_packages, lockfile_packages)

# Check which renv-managed packages are missing from the project library
project_lib <- renv::paths$library(project = renv::project())
missing_in_project_lib <- renv_managed_packages[!vapply(
  renv_managed_packages,
  function(pkg) pkg %in% list.files(project_lib),
  logical(1)
)]

if (length(missing_in_lockfile) == 0 && length(missing_in_project_lib) > 0) {
  renv::restore(prompt = FALSE)
} else if (length(missing_in_lockfile) > 0 || length(missing_in_project_lib) > 0) {
  message("Alguns pacotes são requeridos porém NÃO estão no renv.lock ou na project library")
  message("Pacotes PRESENTES no renv.lock:\n- ", paste(lockfile_packages, collapse = "\n- "))
  message("Pacotes que NÃO estão presentes no renv.lock:\n- ", paste(missing_in_lockfile, collapse = "\n- "))
  message("Pacotes que NÃO estão presentes na project library:\n- ", paste(missing_in_project_lib, collapse = "\n- "))
  if (length(base_or_recommended_packages) > 0) {
    message("Os seguintes pacotes são base/recommended e NÃO são gerenciados pelo renv:\n- ", paste(base_or_recommended_packages, collapse = "\n- "))
  }

  ans <- readline("Deseja tentar instalar a versão mais recente e executar renv::snapshot() para atualizar o renv.lock? (y/n): ")
  if (tolower(ans) %in% c("y", "yes")) {
    # Install all missing renv-managed packages into the project library
    if (length(missing_in_project_lib) > 0) {
      renv::install(missing_in_project_lib)
    }
    # Attach all renv-managed packages from the project library
    invisible(lapply(renv_managed_packages, function(pkg) library(pkg, character.only = TRUE)))
    # Use type = "all" to force full snapshot
    renv::snapshot(type = "all")
    # Re-check lockfile after snapshot
    lockfile_packages <- get_lockfile_packages()
    still_missing <- setdiff(renv_managed_packages, lockfile_packages)
    if (length(still_missing) > 0) {
      warning("Ainda faltam os seguintes pacotes no renv.lock após snapshot:\n- ", paste(still_missing, collapse = "\n- "))
    } else {
      message("renv.lock atualizado.")
    }
  } else {
    stop("renv.lock NÃO foi atualizado. Erros de execução podem ocorrer devido a pacotes faltantes. Fechando a aplicação")
  }
} else {
  lapply(required_packages, function(pkg) library(pkg, character.only = TRUE))
}