local OAuth = require "kong.plugins.google-logging.google.core.oauth"
local HTTPClient = require "kong.plugins.google-logging.google.core.http"
local BatchQueue = require "kong.tools.batch_queue"

local kong = kong
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local socket = require "socket"
local cjson = require "cjson"

local function send_to_logging(oauth, entries, resource, log_id)
  local logging_client = HTTPClient(oauth, "logging.googleapis.com/v2/")
  local log_entries = {}
  for _, entry in pairs(entries) do
    local preciceSeconds = entry.timestamp
    local seconds = math.floor(preciceSeconds)
    local milliSeconds = math.floor((preciceSeconds - seconds) * 1000)
    local isoTime = os.date("!%Y-%m-%dT%T.", seconds) .. tostring(milliSeconds) .. "Z"
    table.insert(log_entries, {
        {
          logName = "projects/" .. oauth:GetProjectID() .. "/logs/" .. log_id,
          resource = resource,
          timestamp = isoTime,
          labels = {
            source = "kong-google-logging"
          },
          jsonPayload = entry.data,
          httpRequest = entry.request,
        },
      })
  end

  local post, code = logging_client:Request("entries:write", {
    entries = log_entries,
    partialSuccess = false,
  }, nil, "POST")
  if code ~= 200 then
    kong.log.err("Failed to write logs: " .. post[1])
    return false, post[1]
  end
  return true
end

local function log_entry()
  local logs = kong.log.serialize()

  local entry = {
    timestamp = socket.gettime(),
    data = {
      upstream_uri = logs.upstream_uri,
      uri = logs.request.uri,
      latency_request = logs.latencies.request,
      latency_gateway = logs.latencies.kong,
      latency_proxy = logs.latencies.proxy,
    },
    request = {
      requestMethod = logs.request.method,
      requestUrl = logs.request.url,
      requestSize = logs.request.size,
      status = logs.response.status,
      responseSize = logs.response.size,
      userAgent = logs.request["user-agent"],
      remoteIp = logs.client_ip,
      serverIp = logs.tries ~= nil and table.getn(logs.tries) > 0 and logs.tries[1].ip or nil,
      latency = tostring(logs.latencies.request / 1000) .. "s",
    }
  }

  if logs.service then
    entry.data.service = logs.service.name
    entry.request.protocol = logs.service.protocol
  end
  if logs.route then entry.data.route = logs.route.name end
  if logs.consumer then entry.data.consumer = logs.consumer.username end

  return entry;
end

-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()

-- constructor
function plugin:new()
  plugin.super.new(self, plugin_name)
  self.queues = {}
  -- cached key file when reading it from disk
  self.key_cache = nil
end

function plugin:get_key(conf)
  -- use the key specified in the config
  if conf.google_key then
    return conf.google_key
  end

  -- read the key from the specified path
  if conf.google_key_file then
    if self.key_file_cache ~= nil then
      return self.key_file_cache
    end

    local file_content = assert(assert(io.open(conf.google_key_file)):read("*a"))
    self.key_file_cache = cjson.decode(file_content)
    return self.key_file_cache
  end

  return nil
end

function plugin:get_queue(conf)
  local sessionKey = 'default'
  local key = self:get_key(conf)
  if key == nil then
    kong.log.err("No key file or key specified")
    return nil
  end

  local existingQueue = self.queues[sessionKey]
  if existingQueue ~= nil then
    return existingQueue
  end

  local scope = "https://www.googleapis.com/auth/logging.write"
  local oauth = OAuth(nil, key, scope)
  if oauth == nil then
    kong.log.err("Failed to create OAuth")
    return nil
  end

  local process = function(entries)
    return send_to_logging(oauth, entries, conf.resource, conf.log_id)
  end

  --     { -- Opts table with control values. Defaults shown:
  --       retry_count    = 0,    -- number of times to retry processing
  --       batch_max_size = 1000, -- max number of entries that can be queued before they are queued for processing
  --       process_delay  = 1,    -- in seconds, how often the current batch is closed & queued
  --       flush_timeout  = 2,    -- in seconds, how much time passes without activity before the current batch is closed and queued
  local q, err = BatchQueue.new(process, {
    retry_count = conf.retry_count,
    flush_timeout = conf.flush_timeout,
    batch_max_size = conf.batch_max_size,
    process_delay = 5,
  })
  if not q then
    kong.log.err("could not create queue: ", err)
    return nil
  end

  self.queues[sessionKey] = q
  return q
end


---[[ runs in the 'log_by_lua_block'
function plugin:log(conf)
  plugin.super.log(self)
  local queue = self:get_queue(conf)
  queue:add(log_entry())
end

return plugin
