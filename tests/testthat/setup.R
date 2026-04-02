# skip dynamic year discovery during tests (avoids HTTP requests to INEP)
Sys.setenv(EDUCABR_SKIP_DISCOVERY = "true")
