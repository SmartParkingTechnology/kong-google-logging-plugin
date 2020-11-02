Kong Plugin - *Google Logging*
====================
Plugin for exporting Kong request data such as service name, route name, consumer name or request latency to Google Cloud Logging.

Exported Data:

- service name
- route name
- consumer name
- upstream_uri
- uri
- latency_request
- latency_gateway
- latency_proxy
- httpRequest (https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#HttpRequest)

The logs are labeled with: `"source": "kong-google-logging"`

## Parameters
| parameter       | required | type               | default                                        |
| --------------- | -------- | ------------------ | ---------------------------------------------- |
| log_id          | false    | string             | cloudresourcemanager.googleapis.com%2Factivity |
| google_key      | false    | record             |                                                |
| - private_key   | true     | string             |                                                |
| - client_email  | true     | string             |                                                |
| - project_id    | true     | string             |                                                |
| - token_uri     | true     | string             |                                                |
| google_key_file | false    | string             |                                                |
| resource        | false    | record             |                                                |
| - type          | true     | string             |                                                |
| - labels        | true     | map(string string) |                                                |
| retry_count     | false    | integer            | 0                                              |
| flush_timeout   | false    | integer            | 2                                              |
| batch_max_size  | false    | integer            | 200                                            |


- *log_id*: The log id in: `projects/[PROJECT_ID]/logs/[LOG_ID]`. (https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry)

Auth: For authenticating with Google one of the following must be specified:
- *google_key*: The key parameters of the private service account
- *google_key_file*: Path to the service account json file
The associated service account need the scope: "https://www.googleapis.com/auth/logging.write"

- *resource*: the google monitor resource (https://cloud.google.com/logging/docs/reference/v2/rest/v2/MonitoredResource)

Batch Queue Params: Log entries are send in batches the following parameters allow to control the Kong BatchQueue
- *retry_count*: number of times to retry processing
- *flush_timeout*: in seconds, how much time passes without activity before the current batch is closed and
- *batch_max_size*: max number of entries that can be queued before they are queued for processing


## License

Copyright 2020 Smart Parking Ltd.

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

