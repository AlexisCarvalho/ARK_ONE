# +------------------------------+
# |                              |
# |     AFFILIATION SERVICE      |
# |                              |
# +------------------------------+

source("../models/user_model.R", chdir = TRUE)
source("../utils/regex.R", chdir = TRUE)
source("../utils/utils.R", chdir = TRUE)
source("../utils/request_handler.R", chdir = TRUE)
source("../utils/response_handler.R", chdir = TRUE)

# +-----------------------+
# |    HELP FUNCTIONS     |
# +-----------------------+

# +-----------------------+
# |   AFFILIATION LOOKUP  |
# +-----------------------+

get_owner_for_analyst <- function(req) {
  # extract analyst id from token
  caller_role <- tryCatch(get_user_role_from_req(req), error = function(e) NULL)
  id_analyst <- tryCatch(get_id_user_from_req(req), error = function(e) NULL)

  if (is.null(caller_role) || is.null(id_analyst)) {
    return(list(status = 'unauthorized', message = 'Invalid or missing token', data = list(id_owner = NULL)))
  }

  # Only analysts may query their owners
  if (caller_role != 'analyst') {
    return(list(status = 'unauthorized', message = 'Only analysts can query their owner', data = list(id_owner = NULL)))
  }

  # Validate extracted id
  if (is_invalid_utf8(id_analyst) || !UUIDvalidate(id_analyst)) {
    return(list(status = 'bad_request', message = 'Invalid analyst ID in token', data = list(id_owner = NULL)))
  }

  # Fetch owner using model
  result <- tryCatch(fetch_owner_for_analyst(id_analyst), error = function(e) e)

  if (inherits(result, 'error')) {
    return(list(status = 'internal_server_error', message = 'Database error while fetching affiliation', data = list(id_owner = NULL)))
  }

  if (!is.data.frame(result) || nrow(result) == 0) {
    return(list(status = 'not_found', message = 'No owner found for this analyst', data = list(id_owner = NULL)))
  }

  list(status = 'success', message = 'Owner found', data = list(id_owner = result$id_owner[1]))
}

