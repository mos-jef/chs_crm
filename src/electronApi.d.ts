export {};

declare global {
  interface Window {
    electronAPI: {
      pickFile: (options?: { filters?: { name: string; extensions: string[] }[] }) =>
        Promise<{ success: boolean; filePath?: string; fileName?: string }>;
      pickFolder: () => Promise<{ success: boolean; folderPath?: string }>;
      scanFolderForPdfs: (
        folderPath: string
      ) => Promise<{ success: boolean; files?: { name: string; path: string }[]; error?: string }>;
      readFileBase64: (filePath: string) => Promise<{ success: boolean; base64?: string; error?: string }>;

      driveAuthStart: () => Promise<{ success: boolean; error?: string }>;
      driveSignOut: () => Promise<{ success: boolean }>;
      driveUploadDocument: (args: {
        state: string;
        county: string;
        fileKey: string;
        categoryFolderName: string;
        filePath: string;
        fileName: string;
        mimeType?: string;
      }) => Promise<{ success: boolean; driveFileId?: string; webViewLink?: string; error?: string }>;
      driveUploadAvatar: (args: {
        filePath: string;
        fileName: string;
        mimeType?: string;
      }) => Promise<{ success: boolean; driveFileId?: string; error?: string }>;
      driveDownloadFile: (args: {
        fileId: string;
        fileName?: string;
      }) => Promise<{ success: boolean; path?: string; error?: string }>;
      driveGetFileMetadata: (args: {
        fileId: string;
      }) => Promise<{ success: boolean; meta?: { id: string; name: string; webViewLink?: string }; error?: string }>;

      claudeExtractDocument: (args: {
        base64: string;
        mimeType?: string;
        fields: { key: string; label: string; description?: string }[];
        categoryLabel?: string;
        county?: string;
        state?: string;
      }) => Promise<{ success: boolean; extracted?: Record<string, any>; error?: string }>;

      sheetsCreate: (args: {
        title?: string;
      }) => Promise<{ success: boolean; spreadsheetId?: string; url?: string; error?: string }>;
      sheetsUpsertRow: (args: {
        spreadsheetId: string;
        rowValues: string[];
      }) => Promise<{ success: boolean; error?: string }>;
      sheetsDeleteRow: (args: {
        spreadsheetId: string;
        fileNumber: string;
      }) => Promise<{ success: boolean; error?: string }>;
      sheetsFullResync: (args: {
        spreadsheetId: string;
        rows: string[][];
      }) => Promise<{ success: boolean; error?: string }>;
    };
  }
}
