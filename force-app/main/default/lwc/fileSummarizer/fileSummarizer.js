import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import summarizeContentDocument from '@salesforce/apex/FileSummarizerController.summarizeContentDocument';
import findRecentFileByName from '@salesforce/apex/FileSummarizerController.findRecentFileByName';
import getSupportedFileTypes from '@salesforce/apex/FileSummarizerController.getSupportedFileTypes';

export default class FileSummarizer extends LightningElement {
    @track isProcessing = false;
    @track hasError = false;
    @track hasSummary = false;
    @track errorMessage = '';
    @track summaryText = '';
    @track uploadedFileName = '';
    @track summaryDate = '';
    @track supportedFileTypes = [];
    
    currentRecordId = null; // For file upload context
    uploadedContentDocumentId = null;

    connectedCallback() {
        this.loadSupportedFileTypes();
    }

    // Load supported file types from Apex
    async loadSupportedFileTypes() {
        try {
            this.supportedFileTypes = await getSupportedFileTypes();
        } catch (error) {
            console.error('Error loading supported file types:', error);
        }
    }

    // Handle file upload completion
    handleUploadFinished(event) {
        try {
            console.log('Full upload event detail:', event.detail);
            console.log('Upload event files:', event.detail.files);
            
            // Get the uploaded files
            const uploadedFiles = event.detail.files;
            
            if (uploadedFiles && uploadedFiles.length > 0) {
                const file = uploadedFiles[0];
                this.uploadedFileName = file.name;
                
                console.log('File object details:');
                console.log('- All properties:', Object.keys(file));
                console.log('- File object:', file);
                
                // Log all possible ID properties
                console.log('- contentDocumentId:', file.contentDocumentId);
                console.log('- documentId:', file.documentId);
                console.log('- contentDocId:', file.contentDocId);
                console.log('- contentVersionId:', file.contentVersionId);
                console.log('- versionId:', file.versionId);
                console.log('- id:', file.id);
                console.log('- Id:', file.Id);
                
                // Try different ways to get the ContentDocumentId
                let contentDocumentId = file.contentDocumentId 
                    || file.documentId 
                    || file.contentDocId
                    || file.contentVersionId
                    || file.versionId
                    || file.id
                    || file.Id;
                
                this.uploadedContentDocumentId = contentDocumentId;
                
                console.log('Selected contentDocumentId:', contentDocumentId);
                
                if (!contentDocumentId) {
                    console.error('No valid ID found in file object');
                    // Try to use the file name to find the recently uploaded file
                    this.findFileByName(file.name);
                    return;
                }
                
                // Show success toast
                this.showToast(
                    'Success',
                    `File "${file.name}" uploaded successfully. Processing summary...`,
                    'success'
                );
                
                // Add a delay to ensure Salesforce has processed the file
                setTimeout(() => {
                    this.processUploadedFile(contentDocumentId);
                }, 3000); // Increased to 3 seconds
            } else {
                this.handleError('Upload Error', 'No files were uploaded or upload event is malformed.');
            }
        } catch (error) {
            console.error('Error in handleUploadFinished:', error);
            this.handleError('Error processing uploaded file', error);
        }
    }

    // Fallback method to find file by name when IDs aren't available
    async findFileByName(fileName) {
        try {
            console.log('Attempting to find file by name:', fileName);
            this.showToast(
                'Info',
                `File "${fileName}" uploaded. Searching for file...`,
                'info'
            );
            
            // Wait a bit longer for the file to be processed
            setTimeout(async () => {
                try {
                    // Call the Apex method to find files by name
                    const contentDocumentId = await findRecentFileByName({ fileName: fileName });
                    
                    if (contentDocumentId && !contentDocumentId.startsWith('Error:')) {
                        console.log('Found file with ID:', contentDocumentId);
                        this.uploadedContentDocumentId = contentDocumentId;
                        this.processUploadedFile(contentDocumentId);
                    } else {
                        this.handleError('File Search Error', contentDocumentId || 'Could not locate the uploaded file. Please try again.');
                    }
                } catch (error) {
                    console.error('Error finding file by name:', error);
                    this.handleError('File Search Error', 'Could not locate the uploaded file. Please try uploading again or check that the file was uploaded successfully.');
                }
            }, 5000); // Wait 5 seconds before searching
            
        } catch (error) {
            console.error('Error in findFileByName:', error);
            this.handleError('Upload Error', 'File upload may have failed. Please try again.');
        }
    }

    // Process the uploaded file and generate summary
    async processUploadedFile(contentDocumentId) {
        this.isProcessing = true;
        this.hasError = false;
        this.hasSummary = false;
        this.errorMessage = '';

        console.log('Processing file with ID:', contentDocumentId);

        if (!contentDocumentId) {
            this.handleError('Processing Error', 'No content document ID available for processing');
            this.isProcessing = false;
            return;
        }

        try {
            // Call Apex method to summarize the document
            const summary = await summarizeContentDocument({ 
                contentDocumentId: contentDocumentId 
            });

            console.log('Summary result:', summary);

            if (summary && !summary.startsWith('Error:')) {
                // Success - display the summary
                this.summaryText = summary;
                this.hasSummary = true;
                this.summaryDate = new Date().toLocaleDateString();
                
                this.showToast(
                    'Success',
                    'Document summary generated successfully!',
                    'success'
                );
            } else {
                // Handle API or processing errors
                this.handleError('Summarization Error', summary || 'Failed to generate summary');
            }
        } catch (error) {
            console.error('Error in processUploadedFile:', error);
            this.handleError('Processing Error', error);
        } finally {
            this.isProcessing = false;
        }
    }

    // Handle errors and display them to the user
    handleError(title, error) {
        this.hasError = true;
        this.hasSummary = false;
        this.isProcessing = false;
        
        // Extract error message
        let errorMsg = '';
        if (typeof error === 'string') {
            errorMsg = error;
        } else if (error?.body?.message) {
            errorMsg = error.body.message;
        } else if (error?.message) {
            errorMsg = error.message;
        } else {
            errorMsg = 'An unexpected error occurred. Please try again.';
        }
        
        this.errorMessage = errorMsg;
        
        // Show error toast
        this.showToast(title, errorMsg, 'error');
        
        // Log error for debugging
        console.error(title + ':', error);
    }

    // Clear results and reset the component
    handleClearResults() {
        this.isProcessing = false;
        this.hasError = false;
        this.hasSummary = false;
        this.errorMessage = '';
        this.summaryText = '';
        this.uploadedFileName = '';
        this.summaryDate = '';
        this.uploadedContentDocumentId = null;
        
        // Reset the file upload component
        const fileUpload = this.template.querySelector('lightning-file-upload');
        if (fileUpload) {
            fileUpload.clearFiles();
        }
        
        this.showToast(
            'Cleared',
            'Results cleared. You can now upload a new file.',
            'info'
        );
    }

    // Copy summary to clipboard
    async handleCopySummary() {
        try {
            if (this.summaryText) {
                await navigator.clipboard.writeText(this.summaryText);
                this.showToast(
                    'Copied',
                    'Summary copied to clipboard!',
                    'success'
                );
            }
        } catch (error) {
            // Fallback for browsers that don't support clipboard API
            this.showToast(
                'Copy Failed',
                'Unable to copy to clipboard. Please select and copy the text manually.',
                'warning'
            );
            console.error('Clipboard copy failed:', error);
        }
    }

    // Utility method to show toast messages
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: variant === 'error' ? 'sticky' : 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    // Getter methods for template conditions
    get hasErrorOrProcessing() {
        return this.hasError || this.isProcessing;
    }

    get canShowResults() {
        return this.hasSummary && !this.isProcessing && !this.hasError;
    }
} 