var cc = DataStudioApp.createCommunityConnector();
var SCRIPT_PROPS = PropertiesService.getScriptProperties();
var USER_PROPS = PropertiesService.getUserProperties();

// Configure in Apps Script: set BRIDGE_BASE_URL script property to your deployed Choreo URL base, e.g. https://<choreo-domain>/bridge
function _getBaseUrl_() {
  var base = SCRIPT_PROPS.getProperty("BRIDGE_BASE_URL");
  if (!base) {
    cc.newUserError()
      .setText(
        "Connector not configured. Set script property BRIDGE_BASE_URL to your bridge base URL (e.g. https://<choreo-domain>/bridge)."
      )
      .throwException();
  }
  return base.replace(/\/$/, "");
}

// Auth: API Key in user properties
function getAuthType() {
  return { type: "KEY" };
}

function isAuthValid() {
  return !!USER_PROPS.getProperty("API_KEY");
}

function setCredentials(request) {
  if (!request || !request.key) {
    cc.newUserError().setText("API key is required").throwException();
  }
  USER_PROPS.setProperty("API_KEY", request.key);
  return { errorCode: "NONE" };
}

function resetAuth() {
  USER_PROPS.deleteProperty("API_KEY");
}

function isAdminUser() {
  return false;
}

// Optional connector configuration
function getConfig(request) {
  var config = cc.getConfig();
  config.setDateRangeRequired(true);
  config
    .newTextInput()
    .setId("category")
    .setName("Category filter (optional)")
    .setPlaceholder("Revenue");
  config
    .newTextInput()
    .setId("limit")
    .setName("Limit (optional)")
    .setPlaceholder("100");
  config
    .newTextInput()
    .setId("offset")
    .setName("Offset (optional)")
    .setPlaceholder("0");
  config
    .newInfo()
    .setId("info")
    .setText(
      "Data source: Finance Bridge on Choreo. Ensure BRIDGE_BASE_URL is set in script properties and API key is provided."
    );
  return config.build();
}

// Schema definition aligned with backend
function getSchema(request) {
  var fields = cc.getFields();
  var types = cc.FieldType;
  var aggs = cc.AggregationType;

  fields.newDimension().setId("id").setName("ID").setType(types.NUMBER);
  fields.newDimension().setId("name").setName("Name").setType(types.TEXT);
  fields
    .newMetric()
    .setId("amount")
    .setName("Amount")
    .setType(types.NUMBER)
    .setAggregation(aggs.SUM);
  fields
    .newDimension()
    .setId("created_at")
    .setName("Created At")
    .setType(types.DATETIME);
  fields
    .newDimension()
    .setId("category")
    .setName("Category")
    .setType(types.TEXT);
  fields
    .newDimension()
    .setId("description")
    .setName("Description")
    .setType(types.TEXT);

  return { schema: fields.build() };
}

function getData(request) {
  var fields = cc.getFields();
  var requestedFieldIds = request.fields.map(function (f) {
    return f.name;
  });
  var fieldSubset = fields.forIds(requestedFieldIds);

  var baseUrl = _getBaseUrl_();
  var apiKey = USER_PROPS.getProperty("API_KEY");
  if (!apiKey) {
    cc.newUserError()
      .setText("Not authorized. Provide API key.")
      .throwException();
  }

  // Build query params from config + dateRange
  var params = [];
  if (request.configParams) {
    if (request.configParams.category)
      params.push(
        "category=" + encodeURIComponent(request.configParams.category)
      );
    if (request.configParams.limit)
      params.push("limit=" + encodeURIComponent(request.configParams.limit));
    if (request.configParams.offset)
      params.push("offset=" + encodeURIComponent(request.configParams.offset));
  }
  if (request.dateRange) {
    // request.dateRange values are YYYYMMDD; backend expects YYYY-MM-DD
    var start = request.dateRange.startDate;
    var end = request.dateRange.endDate;
    if (start)
      params.push(
        "startDate=" +
          start.slice(0, 4) +
          "-" +
          start.slice(4, 6) +
          "-" +
          start.slice(6, 8)
      );
    if (end)
      params.push(
        "endDate=" +
          end.slice(0, 4) +
          "-" +
          end.slice(4, 6) +
          "-" +
          end.slice(6, 8)
      );
  }
  var query = params.length ? "?" + params.join("&") : "";

  var url = baseUrl + "/transactions/export" + query;
  var resp = UrlFetchApp.fetch(url, {
    method: "get",
    muteHttpExceptions: true,
    headers: { "x-api-key": apiKey, Accept: "application/json" },
    followRedirects: true,
  });

  var code = resp.getResponseCode();
  if (code >= 400) {
    var body = resp.getContentText();
    cc.newUserError()
      .setText("Upstream error (" + code + "): " + body)
      .throwException();
  }

  var arr = JSON.parse(resp.getContentText());
  if (!Array.isArray(arr)) {
    // If backend returned ApiResponse shape, unwrap data
    if (arr && arr.data && Array.isArray(arr.data)) {
      arr = arr.data;
    } else {
      cc.newUserError()
        .setText("Unexpected response format from API")
        .throwException();
    }
  }

  var rows = arr.map(function (item) {
    var values = fieldSubset.asArray().map(function (field) {
      switch (field.getId()) {
        case "id":
          return Number(item.id || 0);
        case "name":
          return String(item.name || "");
        case "amount":
          return Number(item.amount || 0);
        case "created_at":
          return String(item.created_at || "");
        case "category":
          return String(item.category || "");
        case "description":
          return String(item.description || "");
        default:
          return null;
      }
    });
    return { values: values };
  });

  return {
    schema: fieldSubset.build(),
    rows: rows,
  };
}
