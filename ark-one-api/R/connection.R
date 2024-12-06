if (!require("DBI")) install.packages("DBI", dependencies = TRUE); library(DBI)
if (!require("RPostgres")) install.packages("RPostgres", dependencies = TRUE); library(RPostgres)


getConn <- function(dbname = Sys.getenv("DB_NAME"), 
                    host = Sys.getenv("DB_HOST"), 
                    port = as.integer(Sys.getenv("DB_PORT")), 
                    user = Sys.getenv("DB_USER"), 
                    password = Sys.getenv("DB_PASSWORD")) {
  
  con <- NULL
  
  tryCatch({
    con <- dbConnect(RPostgres::Postgres(), 
                     dbname = dbname, 
                     host = host, 
                     port = port, 
                     user = user, 
                     password = password)
    return(con)
    
  }, error = function(e) {
    message(paste("Error connecting to database:", e$message))
    return(NULL)  
  })
}