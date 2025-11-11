// Blackbaud Connector - unified async runner for RE queries
section BlackbaudJobConnector;

[DataSource.Kind="BlackbaudJobConnector", Publish="BlackbaudJobConnector.Publish"]
shared BlackbaudJobConnector.Contents = Value.ReplaceType(BlackbaudJobConnectorImpl, BlackbaudJobConnectorType);

ConnectorVersion = "2025.11.11.1";
SharedLibrary = #shared;
Crypto = if Record.HasFields(SharedLibrary, "Crypto") then SharedLibrary[Crypto] else null;
CryptoAlgorithm = if Record.HasFields(SharedLibrary, "CryptoAlgorithm") then SharedLibrary[CryptoAlgorithm] else null;
SupportsPkceHash = Crypto <> null and CryptoAlgorithm <> null and Record.HasFields(Crypto, "CreateHash") and Record.HasFields(CryptoAlgorithm, "SHA256");
PkceCodeChallengeMethod = "S256";
OAuthRedirectUri = "https://oauth.powerbi.com/views/oauthredirect.html";

GetRecordFieldInsensitive = (source as nullable record, fieldName as text) as nullable any =>
let
    keys = if source = null then {} else Record.FieldNames(source),
    matches = if List.Count(keys) = 0 then {} else List.Select(keys, each Text.Lower(_) = Text.Lower(fieldName))
in
    if source = null or List.IsEmpty(matches) then null else Record.Field(source, matches{0});

Base64UrlEncode = (input as binary) as text =>
let
    base64 = Binary.ToText(input, BinaryEncoding.Base64),
    withoutPadding = Text.TrimEnd(base64, {"="}),
    dash = Text.Replace(withoutPadding, "+", "-"),
    underscore = Text.Replace(dash, "/", "_")
in
    underscore;

GeneratePkceCodeVerifier = () as text =>
let
    stripHyphen = (guid as text) as text => Text.Replace(guid, "-", ""),
    combined = stripHyphen(Text.NewGuid()) & stripHyphen(Text.NewGuid()),
    candidate = Text.Start(combined, 64),
    ensureMinLength = if Text.Length(candidate) < 43 then Text.PadEnd(candidate, 43, "a") else candidate
in
    ensureMinLength;

UInt32 = (value as number) as number =>
let
    modded = Number.Mod(value, 4294967296)
in
    if modded < 0 then modded + 4294967296 else modded;

ShiftLeftUnsigned = (value as number, shift as number) as number =>
    UInt32(UInt32(value) * Number.Power(2, shift));

ShiftRightUnsigned = (value as number, shift as number) as number =>
    UInt32(Number.IntegerDivide(UInt32(value), Number.Power(2, shift)));

RotateRight = (value as number, shift as number) as number =>
    UInt32(ShiftRightUnsigned(value, shift) + ShiftLeftUnsigned(value, 32 - shift));

BitwiseNot = (value as number) as number =>
    UInt32(Number.BitwiseXor(UInt32(value), 4294967295));

BitwiseXor3 = (a as number, b as number, c as number) as number =>
    UInt32(Number.BitwiseXor(Number.BitwiseXor(UInt32(a), UInt32(b)), UInt32(c)));

Add32 = (values as list) as number =>
    UInt32(List.Accumulate(values, 0, (state, current) => UInt32(state + UInt32(current))));

Sigma0 = (value as number) as number =>
    BitwiseXor3(RotateRight(value, 7), RotateRight(value, 18), ShiftRightUnsigned(value, 3));

Sigma1 = (value as number) as number =>
    BitwiseXor3(RotateRight(value, 17), RotateRight(value, 19), ShiftRightUnsigned(value, 10));

BigSigma0 = (value as number) as number =>
    BitwiseXor3(RotateRight(value, 2), RotateRight(value, 13), RotateRight(value, 22));

BigSigma1 = (value as number) as number =>
    BitwiseXor3(RotateRight(value, 6), RotateRight(value, 11), RotateRight(value, 25));

Choose = (x as number, y as number, z as number) as number =>
    UInt32(Number.BitwiseXor(Number.BitwiseAnd(UInt32(x), UInt32(y)), Number.BitwiseAnd(BitwiseNot(x), UInt32(z))));

Majority = (x as number, y as number, z as number) as number =>
    UInt32(Number.BitwiseXor(Number.BitwiseXor(Number.BitwiseAnd(UInt32(x), UInt32(y)), Number.BitwiseAnd(UInt32(x), UInt32(z))), Number.BitwiseAnd(UInt32(y), UInt32(z))));

ComputeSha256Binary = (input as text) as binary =>
let
    bytes = Binary.ToList(Text.ToBinary(input, TextEncoding.Utf8)),
    bitLength = List.Count(bytes) * 8,
    paddingRemainder = Number.Mod(List.Count(bytes) + 1, 64),
    zerosNeeded = Number.Mod(64 + 56 - paddingRemainder, 64),
    paddingZeros = List.Repeat({0}, zerosNeeded),
    lengthBytes = {
        0, 0, 0, 0,
        Number.Mod(Number.IntegerDivide(bitLength, 16777216), 256),
        Number.Mod(Number.IntegerDivide(bitLength, 65536), 256),
        Number.Mod(Number.IntegerDivide(bitLength, 256), 256),
        Number.Mod(bitLength, 256)
    },
    padded = List.Combine({bytes, {128}, paddingZeros, lengthBytes}),
    chunkCount = Number.IntegerDivide(List.Count(padded), 64),
    chunks = List.Transform({0..chunkCount - 1}, each List.Range(padded, _ * 64, 64)),
    initialH = {
        1779033703, 3144134277, 1013904242, 2773480762,
        1359893119, 2600822924, 528734635, 1541459225
    },
    kConstants = {
        1116352408, 1899447441, 3049323471, 3921009573,  961987163, 1508970993, 2453635748, 2870763221,
        3624381080,  310598401,  607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580,
        3835390401, 4022224774,  264347078,  604807628,  770255983, 1249150122, 1555081692, 1996064986,
        2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711,  113926993,  338241895,
         666307205,  773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037,
        2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909,  275423344,
         430227734,  506948616,  659060556,  883997877,  958139571, 1322822218, 1537002063, 1747873779,
        1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298
    },
    shaState = List.Accumulate(chunks, initialH, (stateH, chunk) =>
        let
            words16 = List.Transform({0..15}, each
                UInt32(
                    ShiftLeftUnsigned(chunk{_ * 4}, 24) +
                    ShiftLeftUnsigned(chunk{_ * 4 + 1}, 16) +
                    ShiftLeftUnsigned(chunk{_ * 4 + 2}, 8) +
                    chunk{_ * 4 + 3}
                )
            ),
            words = List.Accumulate({16..63}, words16, (wState, idx) =>
                let
                    s0 = Sigma0(wState{idx - 15}),
                    s1 = Sigma1(wState{idx - 2}),
                    newWord = Add32({wState{idx - 16}, s0, wState{idx - 7}, s1})
                in
                    List.Combine({wState, {newWord}})
            ),
            a0 = stateH{0},
            b0 = stateH{1},
            c0 = stateH{2},
            d0 = stateH{3},
            e0 = stateH{4},
            f0 = stateH{5},
            g0 = stateH{6},
            h0 = stateH{7},
            result = List.Accumulate({0..63}, [A = a0, B = b0, C = c0, D = d0, E = e0, F = f0, G = g0, H = h0], (acc, i) =>
                let
                    S1 = BigSigma1(acc[E]),
                    ch = Choose(acc[E], acc[F], acc[G]),
                    temp1 = Add32({acc[H], S1, ch, kConstants{i}, words{i}}),
                    S0 = BigSigma0(acc[A]),
                    maj = Majority(acc[A], acc[B], acc[C]),
                    temp2 = Add32({S0, maj}),
                    newA = Add32({temp1, temp2}),
                    newE = Add32({acc[D], temp1})
                in
                    [
                        A = newA,
                        B = acc[A],
                        C = acc[B],
                        D = acc[C],
                        E = newE,
                        F = acc[E],
                        G = acc[F],
                        H = acc[G]
                    ]
            ),
            updatedH = {
                Add32({stateH{0}, result[A]}),
                Add32({stateH{1}, result[B]}),
                Add32({stateH{2}, result[C]}),
                Add32({stateH{3}, result[D]}),
                Add32({stateH{4}, result[E]}),
                Add32({stateH{5}, result[F]}),
                Add32({stateH{6}, result[G]}),
                Add32({stateH{7}, result[H]})
            }
        in
            updatedH
    ),
    hashBytes = List.Combine(List.Transform(shaState, each {
        Number.Mod(Number.IntegerDivide(_, 16777216), 256),
        Number.Mod(Number.IntegerDivide(_, 65536), 256),
        Number.Mod(Number.IntegerDivide(_, 256), 256),
        Number.Mod(_, 256)
    }))
in
    Binary.FromList(hashBytes);

ComputePkceCodeChallenge = (verifier as text) as text =>
let
    hashed = if SupportsPkceHash then Crypto[CreateHash](CryptoAlgorithm[SHA256], Text.ToBinary(verifier, TextEncoding.Utf8)) else ComputeSha256Binary(verifier)
in
    Base64UrlEncode(hashed);

RequestOAuthToken = (authContext as record, payloadValue as text, grantType as text, optionalCodeVerifier as nullable text) as record =>
        let
            clientId = authContext[client_id],
            clientSecret = if Record.HasFields(authContext, "client_secret") then authContext[client_secret] else null,
            baseRequestFields = [grant_type = grantType, client_id = clientId],
            grantSpecificFields = if grantType = "authorization_code" then
                    [code = payloadValue, redirect_uri = OAuthRedirectUri]
                else if grantType = "refresh_token" then
                    [refresh_token = payloadValue]
                else
                    [],
            pkceField = if optionalCodeVerifier <> null then [code_verifier = optionalCodeVerifier] else [],
            secretField = if clientSecret <> null and clientSecret <> "" then [client_secret = clientSecret] else [],
            bodyFields = Record.Combine({baseRequestFields, grantSpecificFields, pkceField, secretField}),
            content = Text.ToBinary(Uri.BuildQueryString(bodyFields)),
            authorizationHeader = if clientSecret <> null and clientSecret <> "" then
                    [Authorization = "Basic " & Binary.ToText(Text.ToBinary(clientId & ":" & clientSecret), BinaryEncoding.Base64)]
                else
                    [],
            headers = Record.Combine({[#"Content-Type" = "application/x-www-form-urlencoded"], authorizationHeader}),
            tokenResponse = Web.Contents("https://oauth2.sky.blackbaud.com/token", [Content = content, Headers = headers]),
            tokenJson = Json.Document(tokenResponse)
        in
            tokenJson;

BlackbaudJobConnectorType = type function (
    client_id as (type text meta [
        Documentation.FieldCaption = "Client ID",
        Documentation.FieldDescription = "Blackbaud application client ID",
        Documentation.SampleValues = {"your-client-id"}
    ]),
    subscription_key as (type text meta [
        Documentation.FieldCaption = "Subscription Key",
        Documentation.FieldDescription = "SKY API subscription key from Blackbaud developer portal",
        Documentation.SampleValues = {"your-subscription-key"}
    ]),
    optional client_secret as (type nullable text meta [
        Documentation.FieldCaption = "Client Secret",
        Documentation.FieldDescription = "Optional legacy client secret (leave blank for PKCE-only apps)",
        Documentation.SampleValues = {"your-client-secret"}
    ])
) as table meta [
    Documentation.Name = "Blackbaud Connector",
    Documentation.LongDescription = "Version " & ConnectorVersion & " - PKCE-enabled OAuth flow (client secret optional)."
];

BlackbaudJobConnectorImpl = (client_id as text, subscription_key as text, optional client_secret as nullable text) =>
let
    _ = if subscription_key = null or Text.Trim(Text.From(subscription_key)) = "" then error Error.Record("DataSource.Error", "Subscription key is required for the Blackbaud connector.", null) else null,
    subscriptionKeyText = Text.Trim(Text.From(subscription_key)),
    clientSecretPrepared = if client_secret = null then null else Text.From(client_secret),
    clientSecretText =
        let
            trimmed = if clientSecretPrepared = null then null else Text.Trim(clientSecretPrepared)
        in
            if trimmed = null or trimmed = "" then null else trimmed
in
    BlackbaudJobConnectorCore(client_id, subscriptionKeyText, clientSecretText);

BlackbaudJobConnectorCore = (client_id as text, subscription_key as text, optional client_secret as nullable text) =>
let
    auth = [
        client_id = client_id,
        client_secret = client_secret,
        subscription_key = subscription_key
    ],

    reQueryRecordsTry = try GetReQueriesRaw(auth),
    reQueryRecords = if reQueryRecordsTry[HasError] then {} else reQueryRecordsTry[Value],
    reQueryTable = CreateReQueryTable(reQueryRecords),
    reQueryFunction = CreateReQueryExecutionFunction(auth, reQueryRecords),

    instructionsTable = #table(
        {"Step", "Details"},
        {
            {"0", "Blackbaud Connector version " & ConnectorVersion & " (RE queries only)."},
            {"1", "Browse available RE queries to locate IDs."},
            {"2", "Select Run RE Query and choose an ID from the dropdown."},
            {"3", "Jobs run asynchronously. Large workloads can take several minutes."},
            {"4", "CSV results are converted to tables automatically."},
            {"5", "Optional: specify Max Wait Minutes when running RE queries if they require longer than 30 minutes."}
        }
    ),

    navigationRows = {
        [Name = "Browse RE Queries", Key = "re_queries", Data = reQueryTable, ItemKind = "Table", ItemName = "Table", IsLeaf = true],
        [Name = "Run RE Query", Key = "run_re_query", Data = reQueryFunction, ItemKind = "Function", ItemName = "Function", IsLeaf = true],
        [Name = "How It Works", Key = "instructions", Data = instructionsTable, ItemKind = "Table", ItemName = "Table", IsLeaf = true]
    },

    navTable = #table({"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}, List.Transform(navigationRows, each {_[Name], _[Key], _[Data], _[ItemKind], _[ItemName], _[IsLeaf]})),
    navTableWithType =
        let
            tableType = Value.Type(navTable),
            keyedType = Type.AddTableKey(tableType, {"Key"}, true) meta [
                NavigationTable.NameColumn = "Name",
                NavigationTable.DataColumn = "Data",
                NavigationTable.ItemKindColumn = "ItemKind",
                NavigationTable.ItemNameColumn = "ItemName",
                Preview.DelayColumn = "ItemName",
                NavigationTable.IsLeafColumn = "IsLeaf"
            ]
        in
            Value.ReplaceType(navTable, keyedType)
in
    if reQueryRecordsTry[HasError] then
        navTableWithType meta [
            Navigation.Warning = "RE query discovery failed: " & GetErrorText(reQueryRecordsTry[Error])
        ]
    else
        navTableWithType;

CreateReQueryTable = (records as list) as table =>
let
    empty = #table({"Query_ID", "Name", "Description", "Type", "Category", "Last_Run", "Record_Count", "Can_Execute"}, {}),
    result = if List.Count(records) = 0 then
        empty
    else
        let
            raw = Table.FromRecords(records),
            desired = {"id", "name", "description", "type", "category", "date_last_run", "num_records", "can_execute"},
            existing = List.Intersect({desired, Table.ColumnNames(raw)}),
            selected = Table.SelectColumns(raw, existing, MissingField.UseNull),
            renamed = Table.RenameColumns(selected, {
                {"id", "Query_ID"},
                {"name", "Name"},
                {"description", "Description"},
                {"type", "Type"},
                {"category", "Category"},
                {"date_last_run", "Last_Run"},
                {"num_records", "Record_Count"},
                {"can_execute", "Can_Execute"}
            }, MissingField.Ignore)
        in
            renamed
in
    result;

CreateReQueryExecutionFunction = (auth as record, records as list) as function =>
let
    filteredRecords = List.Select(records, each Record.HasFields(_, "id") and Record.HasFields(_, "name")),
    firstQueryId = if List.Count(filteredRecords) > 0 then filteredRecords{0}[id] else null,

    exec = (queryId as number, optional maxWaitMinutes as nullable number) => ExecuteReQueryJob(queryId, auth, maxWaitMinutes),
    typed = Value.ReplaceType(
        exec,
        type function (
            queryId as (type number meta [
                Documentation.FieldCaption = "RE Query ID",
                Documentation.FieldDescription = "Enter the RE Query ID (see Browse RE Queries table for IDs)",
                Documentation.SampleValues = if firstQueryId <> null then {firstQueryId} else {}
            ]),
            optional maxWaitMinutes as (type nullable number meta [
                Documentation.FieldCaption = "Max Wait Minutes",
                Documentation.FieldDescription = "Optional override for how long to wait for job completion (default 30 minutes).",
                Documentation.SampleValues = {30, 60, 120}
            ])
        ) as table meta [
            Documentation.Name = "Execute RE Query",
            Documentation.Description = "Runs the selected RE query via async job API and returns CSV results as a table."
        ]
    )
in
    typed;

ExecuteReQueryJob = (queryId as number, auth as record, optional maxWaitMinutes as nullable number) as table =>
let
    startResponse = StartReQueryJob(queryId, auth),
    jobId = if Record.HasFields(startResponse, "id") then startResponse[id] else error Error.Record("DataSource.Error", "Query job did not return an ID", startResponse),
    effectiveWait = if maxWaitMinutes <> null and maxWaitMinutes > 0 then maxWaitMinutes else 30,
    completion = PollReQueryJob(jobId, auth, effectiveWait),
    sasUri = completion[sas_uri],
    csvBinary = DownloadSasBinary(sasUri),
    csvTable = Csv.Document(csvBinary, [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    result = if Table.IsEmpty(csvTable) then csvTable else Table.PromoteHeaders(csvTable, [PromoteAllScalars = true])
in
    result;

StartReQueryJob = (queryId as number, auth as record) as record =>
let
    body = [
        id = queryId,
        ux_mode = "Asynchronous",
        output_format = "Csv",
        formatting_mode = "UI",
        sql_generation_mode = "Query",
        use_static_query_id_set = false
    ],
    options = [
        Content = Json.FromValue(body),
        Headers = [#"Content-Type" = "application/json"],
        ManualStatusHandling = {400, 401, 403, 404, 409, 429, 500, 503}
    ],
    responseTry = try InvokeQueryApi("queries/executebyid?product=RE&module=None", auth, options),
    json =
        if responseTry[HasError] then
            let
                err = responseTry[Error],
                detail = if Value.Is(err, type record) and Record.HasFields(err, "Detail") then err[Detail] else null,
                status = if Value.Is(detail, type record) and Record.HasFields(detail, "Response.Status") then detail[Response.Status] else null,
                rawBody = if Value.Is(detail, type record) and Record.HasFields(detail, "Response.Body") then detail[Response.Body] else null,
                bodyText = if Value.Is(rawBody, type binary) then Text.FromBinary(rawBody) else if rawBody <> null then Text.From(rawBody) else "",
                message =
                    if status = 404 then
                        "RE query ID " & Number.ToText(queryId) & " was not found or you do not have permission to execute it."
                    else if status = 403 then
                        "Access denied when attempting to execute RE query ID " & Number.ToText(queryId) & "."
                    else if status = 401 then
                        "Authentication failed when attempting to execute RE query ID " & Number.ToText(queryId) & "."
                    else if status = 429 then
                        "RE query execution was throttled. Please wait and try again."
                    else
                        "Failed to start RE query job (HTTP " & (if status <> null then Number.ToText(status) else "unknown") & ").",
                errorInfo = [query_id = queryId, status = status, response_body = bodyText]
            in
                error Error.Record("DataSource.Error", message, errorInfo)
        else
            let
                response = responseTry[Value],
                responseMetadata = Value.Metadata(response),
                status = if Value.Is(responseMetadata, type record) and Record.HasFields(responseMetadata, "Response.Status") then responseMetadata[Response.Status] else null
            in
                if status <> null and status >= 400 then
                    let
                        bodyText = try Text.FromBinary(response) otherwise "",
                        message =
                            if status = 404 then
                                "RE query ID " & Number.ToText(queryId) & " was not found or you do not have permission to execute it."
                            else if status = 403 then
                                "Access denied when attempting to execute RE query ID " & Number.ToText(queryId) & "."
                            else if status = 401 then
                                "Authentication failed when attempting to execute RE query ID " & Number.ToText(queryId) & "."
                            else if status = 429 then
                                "RE query execution was throttled. Please wait and try again."
                            else
                                "Failed to start RE query job (HTTP " & Number.ToText(status) & ").",
                        errorInfo = [query_id = queryId, status = status, response_body = bodyText]
                    in
                        error Error.Record("DataSource.Error", message, errorInfo)
                else
                    Json.Document(response)
in
    json;

PollReQueryJob = (jobId as text, auth as record, maxWaitMinutes as number) as record =>
let
    intervalSeconds = 10,
    waitDuration = #duration(0, 0, 0, intervalSeconds),
    effectiveMinutes = if maxWaitMinutes > 0 then maxWaitMinutes else 30,
    computedAttempts = Number.RoundUp((effectiveMinutes * 60) / intervalSeconds),
    maxAttempts = if computedAttempts < 1 then 1 else computedAttempts,
    failureStatuses = {"Failed", "Cancelled", "Disallowed"},
    createState = (attempt as number, statusValue as any) as record =>
        let
            normalized =
                if Value.Is(statusValue, type record) then statusValue
                else if statusValue = null then [status = "Unknown"]
                else [status = "Unknown", value = statusValue],
            statusText = if Record.HasFields(normalized, "status") and normalized[status] <> null then Text.From(normalized[status]) else "Unknown",
            hasSas = statusText = "Completed" and Record.HasFields(normalized, "sas_uri") and normalized[sas_uri] <> null,
            failed = List.Contains(failureStatuses, statusText),
            done = hasSas or failed
        in
            [
                Attempt = attempt,
                Result = normalized,
                Status = statusText,
                Done = done
            ],
    initialState = createState(1, GetReQueryJobStatus(jobId, auth)),
    states = List.Generate(
        () => initialState,
        each [Attempt] <= maxAttempts,
        each
            if [Done] or [Attempt] >= maxAttempts then
                [Attempt = maxAttempts + 1, Result = [Result], Status = [Status], Done = [Done]]
            else
                let
                    nextAttempt = [Attempt] + 1,
                    nextStatus = Function.InvokeAfter(() => GetReQueryJobStatus(jobId, auth), waitDuration),
                    nextState = createState(nextAttempt, nextStatus)
                in
                    nextState
    ),
    finalState = if List.Count(states) = 0 then [Attempt = 0, Result = null, Status = "Unknown", Done = false] else List.Last(states),
    finalStatus = finalState[Status],
    finalResult = finalState[Result],
    waitedSeconds = (if finalState[Attempt] > 1 then finalState[Attempt] - 1 else 0) * intervalSeconds,
    errorDetails = Record.Combine({finalResult, [job_id = jobId, wait_seconds = waitedSeconds]})
in
    if finalResult = null then
        error Error.Record("DataSource.Error", "RE query job timed out before returning a status. Job ID: " & jobId, null)
    else if finalStatus = "Completed" and Record.HasFields(finalResult, "sas_uri") and finalResult[sas_uri] <> null then
        finalResult
    else if List.Contains(failureStatuses, finalStatus) then
        error Error.Record(
            "DataSource.Error",
            "RE query job failed with status: " & finalStatus & " (Job ID: " & jobId & ")",
            errorDetails
        )
    else
        error Error.Record(
            "DataSource.Error",
            "RE query job timed out after waiting " & Number.ToText(waitedSeconds) & " seconds. Last status: " & finalStatus & " (Job ID: " & jobId & ")",
            errorDetails
        );

GetReQueriesRaw = (auth as record) as list =>
let
    pageSize = 200,
    Fetch = (offset as number) =>
        let
            response = InvokeQueryApi("queries?product=RE&module=None&limit=" & Text.From(pageSize) & "&offset=" & Text.From(offset), auth),
            json = Json.Document(response),
            queries = if Record.HasFields(json, "queries") then json[queries] else {}
        in
            queries,
    pages = List.Generate(
        () => [Offset = 0, Items = Fetch(0)],
        each List.Count([Items]) > 0,
        each [Offset = [Offset] + pageSize, Items = Fetch([Offset] + pageSize)],
        each [Items]
    ),
    combined = if List.Count(pages) = 0 then {} else List.Combine(pages)
in
    combined;

GetReQueryJobStatus = (jobId as text, auth as record) as record =>
let
    // Append a monotonic query value so Power Query cannot reuse prior responses when polling
    cacheBust = Text.From(Number.RoundTowardZero(Duration.TotalSeconds(DateTimeZone.UtcNow() - #datetimezone(1970, 1, 1, 0, 0, 0, 0, 0)) * 1000)),
    options = [
        Query = [
            product = "RE",
            module = "None",
            include_read_url = "OnceCompleted",
            cachebust = cacheBust
        ],
        ManualStatusHandling = {202, 204}
    ],
    responseTry = try InvokeQueryApi("jobs/" & jobId, auth, options),
    result =
        if responseTry[HasError] then
            let
                err = responseTry[Error],
                detail = if Value.Is(err, type record) and Record.HasFields(err, "Detail") then err[Detail] else null,
                statusCode = if Value.Is(detail, type record) and Record.HasFields(detail, "Response.Status") then detail[Response.Status] else null,
                rawBody = if Value.Is(detail, type record) and Record.HasFields(detail, "Response.Body") then detail[Response.Body] else null,
                jsonTry =
                    if rawBody = null then [HasError = true, Error = err]
                    else if Value.Is(rawBody, type binary) then try Json.Document(rawBody)
                    else try Json.Document(Text.ToBinary(Text.From(rawBody))),
                fallback =
                    if statusCode = 202 or statusCode = 204 then [status = "Running"]
                    else if statusCode = 404 then [status = "NotFound"]
                    else null,
                parsed =
                    if jsonTry[HasError] then
                        if fallback <> null then fallback else error err
                    else if jsonTry[Value] = null and fallback <> null then fallback
                    else jsonTry[Value]
            in
                if Value.Is(parsed, type record) then parsed else [status = "Unknown", value = parsed]
        else
            let
                response = responseTry[Value],
                metadata = Value.Metadata(response),
                statusCode = if Value.Is(metadata, type record) and Record.HasFields(metadata, "Response.Status") then metadata[Response.Status] else null,
                jsonTry = try Json.Document(response),
                parsed =
                    if jsonTry[HasError] then
                        if statusCode = 202 or statusCode = 204 then [status = "Running"]
                        else error jsonTry[Error]
                    else if jsonTry[Value] = null then
                        if statusCode = 202 or statusCode = 204 then [status = "Running"]
                        else [status = if statusCode <> null then Text.From(statusCode) else "Unknown"]
                    else jsonTry[Value]
            in
                if Value.Is(parsed, type record) then parsed else [status = "Unknown", value = parsed]
in
    result;

DownloadSasBinary = (sasUri as text) as binary =>
let
    _ = if sasUri = null or Text.Length(Text.Trim(sasUri)) = 0 then error Error.Record("DataSource.Error", "SAS URI is missing", null) else null,
    binary = Web.Contents(sasUri)
in
    binary;

InvokeQueryApi = (relativePath as text, auth as record, optional options as nullable record) as binary =>
let
    url = "https://api.sky.blackbaud.com/query/" & Text.TrimStart(relativePath, "/"),
    response = Web.Contents(url, PrepareRequestOptions(options, auth))
in
    response;

PrepareRequestOptions = (options as nullable record, auth as record) as record =>
let
    base = if options = null then [] else options,
    baseWithoutHeaders = Record.RemoveFields(base, {"Headers"}, MissingField.Ignore),
    existingHeaders = if options <> null and Record.HasFields(options, "Headers") then options[Headers] else [],
    mergedHeaders = Record.Combine({existingHeaders, GetAuthHeaders(auth)}),
    withHeaders = Record.Combine({baseWithoutHeaders, [Headers = mergedHeaders]})
in
    withHeaders;

GetAuthHeaders = (auth as record) as record =>
let
    credentialFunctionTry = try Record.Field(#shared, "Extension.CurrentCredential"),
    credentialFunction = if credentialFunctionTry[HasError] then error Error.Record("DataSource.Error", "Unable to locate OAuth credential provider.", credentialFunctionTry[Error]) else credentialFunctionTry[Value],
    credential = credentialFunction(),
    _ = if credential = null then error Error.Record("DataSource.Error", "OAuth credential is not available. Please sign in again.", null) else null,
    token = if Record.HasFields(credential, "AccessToken") then credential[AccessToken] else if Record.HasFields(credential, "access_token") then credential[access_token] else error Error.Record("DataSource.Error", "Access token is missing in credential.", credential),
    headers = [
        Authorization = "Bearer " & token,
        #"Bb-Api-Subscription-Key" = auth[subscription_key],
        Accept = "application/json",
        #"Cache-Control" = "no-cache",
        Pragma = "no-cache"
    ]
in
    headers;

GetErrorText = (err as any) as text =>
let
    message = if err = null then "Unknown error" else if Value.Is(err, type record) and Record.HasFields(err, "Message") then err[Message] else try Text.From(err) otherwise "Unknown error"
in
    message;

// Data source definition with OAuth flow
BlackbaudJobConnector = [
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath),
            clientIdValue = if Record.HasFields(json, "client_id") then json[client_id] else error Error.Record("DataSource.Error", "Client ID is required for the Blackbaud connector.", null),
            subscriptionKeyValue = if Record.HasFields(json, "subscription_key") then json[subscription_key] else error Error.Record("DataSource.Error", "Subscription key is required for the Blackbaud connector.", null),
            clientSecretValue = if Record.HasFields(json, "client_secret") then json[client_secret] else null,
            clientIdText = Text.Trim(Text.From(clientIdValue)),
            subscriptionKeyText = Text.Trim(Text.From(subscriptionKeyValue)),
            preparedSecret = if clientSecretValue = null then null else Text.From(clientSecretValue),
            trimmedSecret = if preparedSecret = null then null else Text.Trim(preparedSecret),
            normalizedSecret = if trimmedSecret = null or trimmedSecret = "" then null else trimmedSecret,
            baseArgs = { "BlackbaudJobConnector.Contents", clientIdText, subscriptionKeyText },
            args = if normalizedSecret = null then baseArgs else List.Combine({ baseArgs, { normalizedSecret } })
        in
            args,
    Authentication = [
        OAuth = [
            StartLogin = StartLogin,
            FinishLogin = FinishLogin,
            Refresh = Refresh,
            Logout = Logout
        ]
    ]
];

StartLogin = (resourceUrl, state, display) =>
    let
        resourceJson = Json.Document(resourceUrl),
        client_id = resourceJson[client_id],
        client_secret = if Record.HasFields(resourceJson, "client_secret") then resourceJson[client_secret] else null,
        codeVerifier = GeneratePkceCodeVerifier(),
        codeChallenge = ComputePkceCodeChallenge(codeVerifier),
        authorizeUrl = "https://oauth2.sky.blackbaud.com/authorization" & "?" & Uri.BuildQueryString([
            client_id = client_id,
            response_type = "code",
            redirect_uri = OAuthRedirectUri,
            state = state,
            code_challenge_method = PkceCodeChallengeMethod,
            code_challenge = codeChallenge
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = OAuthRedirectUri,
            WindowHeight = 720,
            WindowWidth = 1024,
            Context = [
                client_id = client_id,
                client_secret = client_secret,
                code_verifier = codeVerifier
            ]
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        parts = Uri.Parts(callbackUri),
        query = if Value.Is(parts[Query], type record) then parts[Query] else null,
        fragmentText = if Record.HasFields(parts, "Fragment") then parts[Fragment] else null,
        fragmentQuery =
            if fragmentText = null or Text.Trim(Text.From(fragmentText)) = "" then
                null
            else
                let
                    parsed = try Uri.Parts("https://placeholder/?" & Text.From(fragmentText))
                in
                    if parsed[HasError] then null else if Value.Is(parsed[Value][Query], type record) then parsed[Value][Query] else null,
        combinedQuery =
            if query <> null and fragmentQuery <> null then Record.Combine({query, fragmentQuery})
            else if query <> null then query
            else fragmentQuery,
        code =
            let
                errorText = GetRecordFieldInsensitive(combinedQuery, "error"),
                _ = if errorText <> null then error Error.Record("Authentication.Error", Text.From(errorText), combinedQuery) else null,
                codeValue = GetRecordFieldInsensitive(combinedQuery, "code")
            in
                if codeValue = null then
                    error Error.Record("Authentication.Error", "Authorization response did not include an authorization code.", combinedQuery)
                else
                    Text.From(codeValue),
        authContext = [
            client_id = context[client_id],
            client_secret = if Record.HasFields(context, "client_secret") then context[client_secret] else null
        ],
        codeVerifier = if Record.HasFields(context, "code_verifier") then context[code_verifier] else null,
        tokenJson = RequestOAuthToken(authContext, code, "authorization_code", codeVerifier)
    in
        tokenJson;

Refresh = (resourceUrl, refresh_token) =>
    let
        resourceJson = Json.Document(resourceUrl),
        authContext = [
            client_id = resourceJson[client_id],
            client_secret = if Record.HasFields(resourceJson, "client_secret") then resourceJson[client_secret] else null
        ],
        tokenJson = RequestOAuthToken(authContext, refresh_token, "refresh_token", null)
    in
        tokenJson;

Logout = (token) => "https://oauth2.sky.blackbaud.com/logout";

BlackbaudJobConnector.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = { "Blackbaud Connector", "Run RE NXT queries" },
    LearnMoreUrl = "https://developer.blackbaud.com/skyapi/",
    Version = ConnectorVersion
];
