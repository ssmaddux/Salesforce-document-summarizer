@isTest
public class FileSummarizerControllerTest {
    
    @isTest
    static void testSummarizeFileWithValidContent() {
        // Test the summarizeFile method with valid content
        String testContent = 'This is a test document with some sample content for summarization.';
        String testFileName = 'test-document.txt';
        
        Test.startTest();
        String result = FileSummarizerController.summarizeFile(testContent, testFileName);
        Test.stopTest();
        
        // Verify that a result was returned (actual API call may not work in test context)
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.length() > 0, 'Result should not be empty');
    }
    
    @isTest
    static void testSummarizeFileWithEmptyContent() {
        // Test the summarizeFile method with empty content
        String testContent = '';
        String testFileName = 'empty-document.txt';
        
        Test.startTest();
        String result = FileSummarizerController.summarizeFile(testContent, testFileName);
        Test.stopTest();
        
        // Verify that an error message is returned for empty content
        System.assert(result.contains('Error'), 'Should return error message for empty content');
    }
    
    @isTest
    static void testSummarizeFileWithNullContent() {
        // Test the summarizeFile method with null content
        String testContent = null;
        String testFileName = 'null-document.txt';
        
        Test.startTest();
        String result = FileSummarizerController.summarizeFile(testContent, testFileName);
        Test.stopTest();
        
        // Verify that an error message is returned for null content
        System.assert(result.contains('Error'), 'Should return error message for null content');
    }
    
    @isTest
    static void testFindRecentFileByNameWithValidFile() {
        // Create test data - ContentVersion and ContentDocument
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'test-document.txt';
        cv.VersionData = Blob.valueOf('This is test content for the document summarization feature.');
        cv.FirstPublishLocationId = UserInfo.getUserId();
        
        insert cv;
        
        Test.startTest();
        String result = FileSummarizerController.findRecentFileByName('Test Document.txt');
        Test.stopTest();
        
        // Should find the file and return the ContentDocumentId
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.startsWith('Error'), 'Should not return error message for valid file');
        System.assert(result.startsWith('069'), 'Should return a valid ContentDocument ID');
    }
    
    @isTest
    static void testFindRecentFileByNameWithNonExistentFile() {
        Test.startTest();
        String result = FileSummarizerController.findRecentFileByName('NonExistentFile.txt');
        Test.stopTest();
        
        // Should return error message for non-existent file
        System.assert(result.contains('Error'), 'Should return error message for non-existent file');
    }
    
    @isTest
    static void testFindRecentFileByNameWithEmptyFileName() {
        Test.startTest();
        String result = FileSummarizerController.findRecentFileByName('');
        Test.stopTest();
        
        // Should return error message for empty file name
        System.assert(result.contains('Error'), 'Should return error message for empty file name');
    }
    
    @isTest
    static void testSummarizeContentDocumentWithInvalidId() {
        // Test the summarizeContentDocument method with invalid ID
        String invalidId = '0691234567890123'; // Invalid ContentDocument ID
        
        Test.startTest();
        String result = FileSummarizerController.summarizeContentDocument(invalidId);
        Test.stopTest();
        
        // Verify that an error message is returned for invalid ID
        System.assert(result.contains('Error'), 'Should return error message for invalid ID');
    }
    
    @isTest
    static void testSummarizeContentDocumentWithValidTextFile() {
        // Create test data - ContentVersion and ContentDocument with plain text
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'test-document.txt';
        cv.VersionData = Blob.valueOf('This is test content for the document summarization feature. This text should be readable and processable.');
        cv.FirstPublishLocationId = UserInfo.getUserId();
        
        insert cv;
        
        // Get the ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        Test.startTest();
        String result = FileSummarizerController.summarizeContentDocument(cv.ContentDocumentId);
        Test.stopTest();
        
        // Verify that a result was returned
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.length() > 0, 'Result should not be empty');
    }
    
    @isTest
    static void testSummarizeContentDocumentWithUnsupportedFileType() {
        // Create test data with a binary file that should fail text extraction
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Binary File';
        cv.PathOnClient = 'test-binary.bin';
        cv.VersionData = Blob.valueOf('Binary content that should not be readable as text: \u0000\u0001\u0002\u0003');
        cv.FirstPublishLocationId = UserInfo.getUserId();
        
        insert cv;
        
        // Get the ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        Test.startTest();
        String result = FileSummarizerController.summarizeContentDocument(cv.ContentDocumentId);
        Test.stopTest();
        
        // Should return an error for unsupported file type
        System.assert(result.contains('Error'), 'Should return error message for unsupported file type');
    }
    
    @isTest
    static void testGetSupportedFileTypes() {
        // Test the getSupportedFileTypes method
        Test.startTest();
        List<String> supportedTypes = FileSummarizerController.getSupportedFileTypes();
        Test.stopTest();
        
        // Verify that supported file types are returned
        System.assertNotEquals(null, supportedTypes, 'Supported file types should not be null');
        System.assert(supportedTypes.size() > 0, 'Should return at least one supported file type');
        System.assert(supportedTypes.contains('txt'), 'Should support TXT files');
        // Updated to reflect new supported file types
        System.assertEquals(2, supportedTypes.size(), 'Should return exactly 2 supported file types');
    }
    
    @isTest
    static void testChatMessageConstructors() {
        // Test the ChatMessage inner class constructors
        Test.startTest();
        
        // Test default constructor
        FileSummarizerController.ChatMessage msg1 = new FileSummarizerController.ChatMessage();
        System.assertEquals(null, msg1.role, 'Default constructor should set role to null');
        System.assertEquals(null, msg1.message, 'Default constructor should set message to null');
        
        // Test parameterized constructor
        FileSummarizerController.ChatMessage msg2 = new FileSummarizerController.ChatMessage('user', 'test message');
        System.assertEquals('user', msg2.role, 'Parameterized constructor should set role correctly');
        System.assertEquals('test message', msg2.message, 'Parameterized constructor should set message correctly');
        
        Test.stopTest();
    }
} 