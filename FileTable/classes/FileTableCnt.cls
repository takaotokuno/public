public with sharing class FileTableCnt {
    public class CustomException extends Exception {}
    public static final String ERROR_MESSAGE = 'エラーが発生しました。システム管理者にご連絡ください。::Error Detail:: ';

    public class FileTable {
        @AuraEnabled public String recordId;
        @AuraEnabled public Boolean isErr;
        @AuraEnabled public String errorMsg;
        @AuraEnabled public Integer rowCount;
        @AuraEnabled public List<FileRow> table;
        public FileTable() {
            this.isErr = false;
            this.errorMsg = '';
            this.rowCount = 0;
            this.table = new List<FileRow>();
        }
    }

    public class FileRow {
        @AuraEnabled
        public String thumbImgStyle;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String extension;
        @AuraEnabled
        public String size;
        @AuraEnabled
        public String lastModifiedDate;
        @AuraEnabled
        public String downloadUrl;
    }

    @AuraEnabled(cacheable=true)
    public static FileTable getFileTable(String recordId) {
        FileTable resultTable = new FileTable();
        resultTable.recordId = recordId;
        try {
            List<String> contentDocumentIds = getContentDocumentIds(recordId);
            resultTable.rowCount = contentDocumentIds.size();

            if( resultTable.rowCount != 0) {
                List<ContentVersion> contentVersions = getContentVersions(contentDocumentIds);
                List<FileRow> fileRows = convertVersions2FileRows(contentVersions);
                resultTable.table = fileRows;
            }

            if( Test.isRunningTest() && recordId == 'customError' ) {
                throw new CustomException();
            }
            
        } catch(Exception e) {
            resultTable.isErr = true;
            resultTable.errorMsg = ERROR_MESSAGE + e.getMessage();
        }
        return resultTable;
    }

    private static List<String> getContentDocumentIds(String recordId) {
        List<String> contentDocumentIds = new List<String>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        contentDocumentLinks = [SELECT ContentDocumentId
                                FROM ContentDocumentLink
                                WHERE LinkedEntityId =:recordId];
        for( ContentDocumentLink resultLink : contentDocumentLinks ) {
            contentDocumentIds.add(String.valueOf(resultLink.ContentDocumentId));
        }
        return contentDocumentIds;
    }

    private static List<ContentVersion> getContentVersions(List<String> contentDocumentIds) {
        List<ContentVersion> contentVersions;
        contentVersions = [SELECT Id, Title, FileExtension, ContentSize, LastModifiedDate
                           FROM ContentVersion
                           WHERE ContentDocumentId IN :contentDocumentIds
                           AND IsMajorVersion = True];      
        return contentVersions;
    }

    private static List<FileRow> convertVersions2FileRows(List<ContentVersion> contentVersions) {
        List<FileRow> fileRows = new List<fileRow>();
        String REQUEST_HOST = URL.getCurrentRequestUrl().getHost();
        String THUMB_IMG_STYLE_BEFORE = 'background-image: url("https://' + REQUEST_HOST + '/sfc/servlet.shepherd/version/renditionDownload?rendition=thumb240BY180&versionId=';
        String THUMB_IMG_STYLE_AFTER = '"); background-repeat: no-repeat; background-size: 100% auto; height: 5rem;';
        String DOWNLOAD_URL_BEFORE = 'https://' + REQUEST_HOST + '/sfc/servlet.shepherd/version/download/';

        for( ContentVersion record : contentVersions ) {
            FileRow fileRow = new FileRow();
            fileRow.thumbImgStyle = THUMB_IMG_STYLE_BEFORE + String.valueOf(record.Id) + THUMB_IMG_STYLE_AFTER;
            fileRow.title = record.Title;
            fileRow.extension = record.FileExtension;
            if(record.ContentSize >= 1000000){
                Decimal fileSize = Decimal.valueOf(record.ContentSize).divide(1000000, 1);
                fileRow.size = String.valueOf(fileSize) + 'MB';
            }else{
                fileRow.size = String.valueOf(record.ContentSize/1000) + 'KB';
            }
            
            fileRow.lastModifiedDate = record.LastModifiedDate.format('yyyy/MM/dd HH:mm');
            fileRow.downloadUrl = DOWNLOAD_URL_BEFORE + String.valueOf(record.Id);

            fileRows.add(fileRow);
        }

        return fileRows;
    }
}