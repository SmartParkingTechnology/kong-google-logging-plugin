return {
  name = "google-logging",
  fields = {
    { config = {
        type = "record",
        fields = {
          {
            google_key = {
              type = "record",
              required = true,
              fields = {
                { private_key = { type = "string", required = true },},
                { client_email = { type = "string", required = true },},
                { project_id = { type = "string", required = true },},
                { token_uri = { type = "string", required = true },},
              }
            }
          },
          { log_id = { type = "string", required = false, default = "cloudresourcemanager.googleapis.com%2Factivity"},},
          { resource = {
            type = "record",
            required = false,
            fields = {
              { type = { type = "string", required = true },},
              { labels = { type = "map", keys = { type = "string" }, values = { type = "string" } }},
            }
          }},
          -- batch params
          { retry_count = { type = "integer", required = false, default = 0 },},
          { flush_timeout = { type = "integer", required = false, default = 2 },},
          { batch_max_size = { type = "integer", required = false, default = 200 },},
        },
      },
    },
  }
}
