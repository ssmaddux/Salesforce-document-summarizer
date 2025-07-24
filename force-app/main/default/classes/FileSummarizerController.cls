public with sharing class FileSummarizerController {
    
    @AuraEnabled
    public static String summarizeFile(String fileContent, String fileName) {
        try {
            // Validate input
            if (String.isBlank(fileContent)) {
                return 'Error: File content is empty or invalid.';
            }
            
            // Call the summarization method
            return generateSummary(fileContent, fileName);
            
        } catch (Exception e) {
            System.debug('Error in summarizeFile: ' + e.getMessage());
            return 'Error processing file: ' + e.getMessage();
        }
    }
    
    @AuraEnabled
    public static String findRecentFileByName(String fileName) {
        try {
            System.debug('FileSummarizerController: Searching for file by name: ' + fileName);
            
            if (String.isBlank(fileName)) {
                return 'Error: No file name provided for search.';
            }
            
            // Search for recently uploaded files with this name
            // Look for files uploaded in the last 5 minutes
            DateTime fiveMinutesAgo = DateTime.now().addMinutes(-5);
            
            List<ContentDocument> contentDocs = [
                SELECT Id, Title, FileExtension, CreatedDate
                FROM ContentDocument 
                WHERE Title = :fileName.substringBeforeLast('.')
                AND CreatedDate >= :fiveMinutesAgo
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (contentDocs.isEmpty()) {
                // Try without removing extension
                contentDocs = [
                    SELECT Id, Title, FileExtension, CreatedDate
                    FROM ContentDocument 
                    WHERE Title = :fileName
                    AND CreatedDate >= :fiveMinutesAgo
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }
            
            if (contentDocs.isEmpty()) {
                // Try a broader search with LIKE
                String searchPattern = '%' + fileName.substringBeforeLast('.') + '%';
                contentDocs = [
                    SELECT Id, Title, FileExtension, CreatedDate
                    FROM ContentDocument 
                    WHERE Title LIKE :searchPattern
                    AND CreatedDate >= :fiveMinutesAgo
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
            }
            
            if (contentDocs.isEmpty()) {
                System.debug('FileSummarizerController: No matching files found for: ' + fileName);
                return 'Error: Could not find recently uploaded file with name: ' + fileName;
            }
            
            String contentDocumentId = contentDocs[0].Id;
            System.debug('FileSummarizerController: Found file with ID: ' + contentDocumentId);
            
            return contentDocumentId;
            
        } catch (Exception e) {
            System.debug('Error in findRecentFileByName: ' + e.getMessage());
            return 'Error searching for file: ' + e.getMessage();
        }
    }
    
    @AuraEnabled
    public static String summarizeContentDocument(String contentDocumentId) {
        try {
            System.debug('FileSummarizerController: Processing ID: ' + contentDocumentId);
            
            // Validate input
            if (String.isBlank(contentDocumentId)) {
                return 'Error: No file ID provided.';
            }
            
            // Determine if this is a ContentDocumentId or ContentVersionId
            String actualContentDocumentId = contentDocumentId;
            
            // Check if the ID starts with '068' (ContentVersion) or '069' (ContentDocument)
            if (contentDocumentId.startsWith('068')) {
                System.debug('FileSummarizerController: Received ContentVersionId, converting to ContentDocumentId');
                // This is a ContentVersionId, we need to get the ContentDocumentId
                List<ContentVersion> cvList = [
                    SELECT ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :contentDocumentId 
                    LIMIT 1
                ];
                
                if (cvList.isEmpty()) {
                    return 'Error: ContentVersion not found with ID: ' + contentDocumentId;
                }
                
                actualContentDocumentId = cvList[0].ContentDocumentId;
                System.debug('FileSummarizerController: Converted to ContentDocumentId: ' + actualContentDocumentId);
            }
            
            // Query the ContentVersion to get the file data
            List<ContentVersion> contentVersions = [
                SELECT Id, Title, FileExtension, TextPreview, VersionData, FileType, ContentSize
                FROM ContentVersion 
                WHERE ContentDocumentId = :actualContentDocumentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            System.debug('FileSummarizerController: Found ' + contentVersions.size() + ' ContentVersion records');
            
            if (contentVersions.isEmpty()) {
                // Try alternative query in case of timing issues
                System.debug('FileSummarizerController: Trying alternative query...');
                contentVersions = [
                    SELECT Id, Title, FileExtension, TextPreview, VersionData, FileType, ContentSize
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :actualContentDocumentId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                
                if (contentVersions.isEmpty()) {
                    return 'Error: File not found. ContentDocumentId: ' + actualContentDocumentId + '. Please try uploading the file again.';
                }
            }
            
            ContentVersion cv = contentVersions[0];
            System.debug('FileSummarizerController: Processing file - Title: ' + cv.Title + ', Extension: ' + cv.FileExtension + ', FileType: ' + cv.FileType + ', Size: ' + cv.ContentSize);
            
            String fileContent = '';
            String fileName = cv.Title;
            if (String.isNotBlank(cv.FileExtension)) {
                fileName += '.' + cv.FileExtension;
            }
            
            // Enhanced file type handling
            String fileType = cv.FileType != null ? cv.FileType.toLowerCase() : '';
            
            // Check if TextPreview is available first (best option for most files)
            if (String.isNotBlank(cv.TextPreview)) {
                System.debug('FileSummarizerController: Using TextPreview for content extraction');
                fileContent = cv.TextPreview;
            } 
            // Handle specific file types
            else if (fileType.contains('text') || fileType.contains('txt')) {
                System.debug('FileSummarizerController: Processing plain text file');
                try {
                    fileContent = cv.VersionData.toString();
                } catch (Exception e) {
                    return 'Error: Unable to read text file content: ' + e.getMessage();
                }
            }
            // For Word documents, PDFs, and other complex formats
            else if (fileType.contains('word') || fileType.contains('pdf') || fileType.contains('document')) {
                System.debug('FileSummarizerController: Processing complex document format: ' + fileType);
                
                // Try TextPreview again (sometimes it's available even when initially blank)
                if (String.isNotBlank(cv.TextPreview)) {
                    fileContent = cv.TextPreview;
                } else {
                    // Provide specific guidance based on file type
                    String fileTypeGuidance = getFileTypeGuidance(fileType);
                    return 'Error: Cannot extract text from ' + fileType.toUpperCase() + ' files automatically. ' + fileTypeGuidance;
                }
            }
            // Try generic text extraction for other formats
            else if (cv.VersionData != null) {
                System.debug('FileSummarizerController: Trying generic text extraction for file type: ' + fileType);
                try {
                    String rawContent = cv.VersionData.toString();
                    // Check if the content looks like readable text
                    if (isReadableText(rawContent)) {
                        fileContent = rawContent;
                    } else {
                        String fileTypeGuidance = getFileTypeGuidance(fileType);
                        return 'Error: File appears to be in binary or encoded format (' + fileType.toUpperCase() + '). ' + fileTypeGuidance;
                    }
                } catch (Exception e) {
                    String fileTypeGuidance = getFileTypeGuidance(fileType);
                    return 'Error: Unable to extract text from this file format (' + fileType.toUpperCase() + '). ' + fileTypeGuidance;
                }
            } else {
                return 'Error: No readable content found in the uploaded file. Please try with a different file format.';
            }
            
            // Validate extracted content
            if (String.isBlank(fileContent) || fileContent.trim().length() == 0) {
                String fileTypeGuidance = getFileTypeGuidance(fileType);
                return 'Error: No text content could be extracted from the file. ' + fileTypeGuidance;
            }
            
            System.debug('FileSummarizerController: Extracted content length: ' + fileContent.length());
            
            // Generate summary
            return generateSummary(fileContent, fileName);
            
        } catch (Exception e) {
            System.debug('Error in summarizeContentDocument: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return 'Error processing file: ' + e.getMessage() + '. Please try again or contact your administrator.';
        }
    }
    
    // Helper method to provide file type specific guidance
    private static String getFileTypeGuidance(String fileType) {
        if (String.isBlank(fileType)) {
            return 'Please try uploading a plain text (.txt) file or convert your document to a text format.';
        }
        
        fileType = fileType.toLowerCase();
        
        if (fileType.contains('word') || fileType.contains('docx') || fileType.contains('doc')) {
            return 'For Word documents: 1) Save as Plain Text (.txt), 2) Copy/paste content into a .txt file, or 3) Try a different Word document that may have better text extraction support.';
        } else if (fileType.contains('pdf')) {
            return 'For PDF files: 1) Save as Plain Text (.txt), 2) Copy/paste content into a .txt file, or 3) Try a text-based PDF (not scanned images).';
        } else {
            return 'Please convert your file to plain text (.txt) format or try uploading a different file type.';
        }
    }
    
    // Helper method to check if content looks like readable text
    private static Boolean isReadableText(String content) {
        if (String.isBlank(content) || content.length() < 10) {
            return false;
        }
        
        // Check if content has a reasonable ratio of printable characters
        Integer printableChars = 0;
        Integer totalChars = Math.min(content.length(), 500); // Check first 500 chars
        
        for (Integer i = 0; i < totalChars; i++) {
            Integer charCode = content.charAt(i);
            // Printable ASCII characters, plus common Unicode characters
            if ((charCode >= 32 && charCode <= 126) || charCode == 9 || charCode == 10 || charCode == 13) {
                printableChars++;
            }
        }
        
        // If more than 80% of characters are printable, consider it readable text
        return (printableChars * 100 / totalChars) > 80;
    }
    
    private static String generateSummary(String content, String fileName) {
        try {
            System.debug('FileSummarizerController: Starting summary generation for file: ' + fileName);
            
            // Truncate content if it's too long (Models API has limits)
            Integer maxContentLength = 10000; // Adjust based on your API limits
            if (content.length() > maxContentLength) {
                content = content.substring(0, maxContentLength) + '... [Content truncated]';
                System.debug('FileSummarizerController: Content truncated to ' + maxContentLength + ' characters');
            }
            
            // Escape special characters in the content for JSON
            String escapedContent = content
                .replace('\\', '\\\\') // Escape backslashes
                .replace('"', '\\"')   // Escape double quotes
                .replace('\n', '\\n')  // Escape newlines
                .replace('\r', '\\r')  // Escape carriage returns
                .replace('\t', '\\t'); // Escape tabs
            
            // Construct the prompt for summarization
            String instructions = '[{"role": "user", "message": "Please provide a concise summary of the following document (' + fileName + ') in 1-2 paragraphs. Focus on the main points and key information. Do not use asterisks, bullet points, or special formatting - write in plain text only. Keep the response conversational and to the point: ' + escapedContent + '"}]';
            
            // Deserialize into ChatMessage objects
            List<FileSummarizerController.ChatMessage> messages = (List<FileSummarizerController.ChatMessage>) JSON.deserialize(
                instructions,
                List<FileSummarizerController.ChatMessage>.class
            );
            
            // Instantiate the Models API
            aiplatform.ModelsAPI modelsAPI = new aiplatform.ModelsAPI();
            
            // Prepare the request and body objects
            aiplatform.ModelsAPI.createChatGenerations_Request request = new aiplatform.ModelsAPI.createChatGenerations_Request();
            aiplatform.ModelsAPI_ChatGenerationsRequest body = new aiplatform.ModelsAPI_ChatGenerationsRequest();
            
            // Specify the model (same as in DashboardController)
            request.modelName = 'sfdc_ai__DefaultVertexAIGemini25Flash001';
            
            // Create message requests
            List<aiplatform.ModelsAPI_ChatMessageRequest> messagesList = new List<aiplatform.ModelsAPI_ChatMessageRequest>();
            
            for (ChatMessage msg : messages) {
                aiplatform.ModelsAPI_ChatMessageRequest messageRequest = new aiplatform.ModelsAPI_ChatMessageRequest();
                messageRequest.content = msg.message != null ? msg.message : '';
                messageRequest.role = msg.role != null ? msg.role : 'user';
                messagesList.add(messageRequest);
            }
            
            // Set the messages in the request body
            body.messages = messagesList;
            request.body = body;
            
            String response = '';
            
            System.debug('FileSummarizerController: Calling Models API...');
            
            // Call the API
            aiplatform.ModelsAPI.createChatGenerations_Response apiResponse = modelsAPI.createChatGenerations(request);
            
            // Process the response
            if (apiResponse?.Code200?.generationDetails?.generations != null &&
                !apiResponse.Code200.generationDetails.generations.isEmpty()) {
                response = apiResponse.Code200.generationDetails.generations[0].content;
                System.debug('FileSummarizerController: Successfully generated summary');
            } else {
                response = 'No summary could be generated for this file. The AI service may be temporarily unavailable.';
                System.debug('FileSummarizerController: No response content from Models API');
            }
            
            return response;
            
        } catch(aiplatform.ModelsAPI.createChatGenerations_ResponseException e) {
            System.debug('Models API Response code: ' + e.responseCode);
            System.debug('Models API Exception: ' + e);
            return 'Unable to generate summary. AI service error (code: ' + e.responseCode + '). Please try again later.';
        } catch (Exception e) {
            System.debug('Error in generateSummary: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return 'Error generating summary: ' + e.getMessage();
        }
    }
    
    // Helper method to get supported file types
    @AuraEnabled(cacheable=true)
    public static List<String> getSupportedFileTypes() {
        return new List<String>{'txt', 'rtf'};
    }
    
    // Inner class for chat messages (similar to DashboardController)
    public class ChatMessage {
        public String role;
        public String message;
        
        public ChatMessage() {}
        
        public ChatMessage(String role, String message) {
            this.role = role;
            this.message = message;
        }
    }
} 