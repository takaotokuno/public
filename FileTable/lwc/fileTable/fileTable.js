import { LightningElement, api, wire } from 'lwc';
import getFileTable from '@salesforce/apex/FileTableCnt.getFileTable';
import FILE_LABEL from '@salesforce/label/c.Noun_File';
const COLUMNS = [
    { cellAttributes: { style: { fieldName: 'thumbImgStyle' }}, initialWidth: 160, hideDefaultActions: true},
    { label: 'タイトル', fieldName: 'title', type: 'text', hideDefaultActions: true},
    { label: '拡張子', fieldName: 'extension', type: 'text', initialWidth: 80, hideDefaultActions: true},
    { label: 'サイズ', fieldName: 'size', type: 'text', initialWidth: 80, hideDefaultActions: true},
    { label: '最終更新日', fieldName: 'lastModifiedDate', type: 'text', initialWidth: 160, hideDefaultActions: true},
    { label: 'ダウンロード', fieldName: 'downloadUrl', type: 'url', initialWidth: 120, hideDefaultActions: true, 
        typeAttributes: { label: 'ダウンロード', tooltip: { fieldName: 'title' }, target: '_blank'}
    }
];

export default class FileTable extends LightningElement {
    // private variable
    @api recordId;
    fileLabel = (FILE_LABEL) ? FILE_LABEL : 'ファイル';
    title = this.fileLabel + '(0)' ;
    columns = COLUMNS;
    table;

    @wire(getFileTable, { recordId: '$recordId'})
    setFileTable({data,error}) {
        if(data && !data.isErr){
            if(!data.isErr){
                this.title = this.fileLabel + '(' + data.rowCount + ')' ;
                this.table = data.table;
                console.log(data);
            }else{
                console.log(data);
                console.error(data.errorMsg);
            }
        }else{
            console.error(error);
        }
    }
}