$currentDateTime = Get-Date -Format "yyyyMMddHHmmss"

# Get Current Folder Path
$DATA_DIR = @(Split-Path $script:myInvocation.MyCommand.Path -Parent).Trim()
$ROOT_DIR = Split-Path -Path $DATA_DIR

# Directory/File Path Setting
$CONF_DIR = $DATA_DIR + "\conf"
if($Args){
    $CONF_FILE = $CONF_DIR + "\" + $Args[0]
}else{
    $CONF_FILE = $CONF_DIR + "\config-sample.ini"
}
$PREF_FILE = $CONF_DIR + "\preference.ini"
$LOG_DIR = $DATA_DIR + "\log"
$LOG_FILE = $LOG_DIR + "\dataloader" + $currentDateTime + ".log"
$SETTING_FILE = $LOG_DIR + "\setting" + $currentDateTime + ".log"
$STATUS_DIR = $DATA_DIR + "\status"
$OUTPUT_DIR = $ROOT_DIR + "\Out"
$INPUT_DIR = $ROOT_DIR + "\In"

# Read Config File
$CONF_PARAMATER = @{}
(Get-Content $CONF_FILE).Replace("\","\\") | %{$CONF_PARAMATER += ConvertFrom-StringData $_}

$PREF_PARAMATER = @{}
(Get-Content $PREF_FILE).Replace("\","\\") | %{$PREF_PARAMATER += ConvertFrom-StringData $_}

# Other DataLoader Setting
$JAR_FILE = $PREF_PARAMATER.DL_PATH + "\" + $PREF_PARAMATER.JAR_FILE
$JAVA_EXE = $env:JAVA_HOME + "\bin\java.exe"

# Set Value of Common Arguments
$argumentList = @(
    "-cp",
    $JAR_FILE,
    "com/salesforce/dataloader/process/DataLoaderRunner",
    ("salesforce.config.dir=" + $CONF_DIR),
    "run.mode=batch",
    ("process.operation=" + $CONF_PARAMATER.OPERATION),
    ("process.encryptionKeyFile=" + $CONF_DIR + "\dataLoader.key"),
    ("process.lastRunOutputDirectory=" + $LOG_DIR),
    ("sfdc.debugMessagesFile=" + $LOG_DIR),
    ("dataAccess.readUTF8=" + $CONF_PARAMATER.IS_UTF8),
    ("dataAccess.writeUTF8=" + $CONF_PARAMATER.IS_UTF8),
    ("sfdc.endpoint=" + $CONF_PARAMATER.LOGIN_URL),
    ("sfdc.entity=" + $CONF_PARAMATER.OBJECT),
    ("sfdc.password=" + $CONF_PARAMATER.PASSWORD),
    ("sfdc.proxyHost=" + $PREF_PARAMATER.PROXY_HOST),
    ("sfdc.proxyPassword=" + $PREF_PARAMATER.PROXY_PASSWORD),
    ("sfdc.proxyPort=" + $PREF_PARAMATER.PROXY_PORT),
    ("sfdc.proxyUsername=" + $PREF_PARAMATER.PROXY_USERNAME),
    ("sfdc.username=" + $CONF_PARAMATER.USERNAME)
)

# Set Value of Read/Write Arguments
if($CONF_PARAMATER.OPERATION -eq "extract"){
    # SOQL Setting
    $SOQL_FILE = $CONF_DIR + "\soql\" + $CONF_PARAMATER.SOQL_FILE
    $SOQL = """" + (Get-Content $SOQL_FILE -Raw).Replace("`r`n"," ") + """"

    $argumentList += ("process.name=read")
    $argumentList += ("dataAccess.name=" + $OUTPUT_DIR + "\" + $CONF_PARAMATER.ACCESS_FILE)
    $argumentList += ("dataAccess.readBatchSize=" + $CONF_PARAMATER.BATCH_SIZE)
    $argumentList += ("sfdc.extractionSOQL=" + $SOQL)
}else{
    $errorFile = $STATUS_DIR + "\" + $currentDateTime + "_Error_" + $CONF_PARAMATER.OPERATION + "_" + $CONF_PARAMATER.ACCESS_FILE
    $successFile = $STATUS_DIR + "\" + $currentDateTime + "_Success_" + $CONF_PARAMATER.OPERATION + "_" + $CONF_PARAMATER.ACCESS_FILE

    $argumentList += ("process.name=write")
    $argumentList += ("dataAccess.name=" + $INPUT_DIR + "\" + $CONF_PARAMATER.ACCESS_FILE)
    $argumentList += ("process.mappingFile=" + $CONF_DIR + "\map\" + $CONF_PARAMATER.MAP_FILE)
    $argumentList += ("process.outputError=" + $errorFile)
    $argumentList += ("process.outputSuccess=" + $successFile)
    $argumentList += ("sfdc.loadBatchSize=" + $CONF_PARAMATER.BATCH_SIZE)
}

# Set Value of DML Arguments
if($CONF_PARAMATER.OPERATION -eq "upsert"){
    $argumentList += ("sfdc.externalIdField=" + $CONF_PARAMATER.KEY_FIELD)
}

if(($CONF_PARAMATER.OPERATION -eq "upsert") -Or ($CONF_PARAMATER.OPERATION -eq "update")){
    $argumentList += ("sfdc.insertNulls=" + $CONF_PARAMATER.NEED_INSERT_NULL)
}

# Call DataLoader
Set-Content -Path $SETTING_FILE -Value $argumentList
Start-Process -FilePath $JAVA_EXE -ArgumentList $argumentList -RedirectStandardOutput $LOG_FILE -Wait

exit