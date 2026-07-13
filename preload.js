const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  pickFile: (options) => ipcRenderer.invoke('pick-file', options),
  pickFolder: () => ipcRenderer.invoke('pick-folder'),
  scanFolderForPdfs: (folderPath) =>
    ipcRenderer.invoke('scan-folder-for-pdfs', folderPath),
  readFileBase64: (filePath) => ipcRenderer.invoke('read-file-base64', filePath),

  driveAuthStart: () => ipcRenderer.invoke('drive-auth-start'),
  driveSignOut: () => ipcRenderer.invoke('drive-sign-out'),
  driveUploadDocument: (args) => ipcRenderer.invoke('drive-upload-document', args),
  driveUploadAvatar: (args) => ipcRenderer.invoke('drive-upload-avatar', args),
  driveDownloadFile: (args) => ipcRenderer.invoke('drive-download-file', args),
  driveGetFileMetadata: (args) => ipcRenderer.invoke('drive-get-file-metadata', args),

  claudeExtractDocument: (args) => ipcRenderer.invoke('claude-extract-document', args),

  sheetsCreate: (args) => ipcRenderer.invoke('sheets-create', args),
  sheetsUpsertRow: (args) => ipcRenderer.invoke('sheets-upsert-row', args),
  sheetsDeleteRow: (args) => ipcRenderer.invoke('sheets-delete-row', args),
  sheetsFullResync: (args) => ipcRenderer.invoke('sheets-full-resync', args),
});
