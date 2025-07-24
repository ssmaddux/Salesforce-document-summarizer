# 📄 Document Summarizer for Salesforce

An AI-powered Lightning Web Component that automatically generates concise summaries of uploaded text documents using Salesforce's Models API.

## 🚀 Features

- **Smart File Upload**: Drag & drop or click to upload text files
- **AI-Powered Summarization**: Uses Salesforce's AI Platform Models API (Gemini 2.5 Flash)
- **Responsive Design**: Works on desktop and mobile devices
- **Real-time Processing**: Live status updates and progress indicators
- **Error Handling**: Comprehensive error messages with helpful guidance
- **Copy to Clipboard**: One-click copying of generated summaries
- **File Type Validation**: Optimized for plain text files with clear user guidance

## 📋 Prerequisites

- Salesforce org with Lightning Experience enabled
- Access to Salesforce AI Platform Models API
- Appropriate permissions for:
  - File upload/management
  - Apex class deployment
  - Lightning Web Component deployment

## 🛠️ Installation

### 1. Deploy to Salesforce

```bash
# Clone the repository
git clone https://github.com/[your-username]/salesforce-document-summarizer.git
cd salesforce-document-summarizer

# Deploy to your Salesforce org
sfdx force:source:deploy -p force-app/

# Or using VS Code Salesforce Extension:
# Right-click on force-app folder → SFDX: Deploy Source to Org
```

### 2. Add Component to Lightning Page

1. Navigate to **Lightning App Builder**
2. Edit an existing page or create a new one
3. Add the **fileSummarizer** component from the Custom Components section
4. Save and activate the page

### 3. Verify Models API Access

Ensure your Salesforce org has access to the AI Platform Models API and the Gemini model being used.

## 📁 Project Structure

```
force-app/main/default/
├── classes/
│   ├── FileSummarizerController.cls          # Main Apex controller
│   ├── FileSummarizerController.cls-meta.xml
│   ├── FileSummarizerControllerTest.cls      # Test class
│   └── FileSummarizerControllerTest.cls-meta.xml
└── lwc/
    └── fileSummarizer/
        ├── fileSummarizer.html               # Component template
        ├── fileSummarizer.js                 # JavaScript controller
        ├── fileSummarizer.css                # Styling
        └── fileSummarizer.js-meta.xml        # Component metadata
```

## 🎯 Usage

### For End Users

1. **Upload a File**:
   - Navigate to a page with the Document Summarizer component
   - Drag & drop a `.txt` file or click "Choose Text File to Summarize"
   - Wait for the file to upload (green success message appears)

2. **Processing**:
   - The system automatically processes your file
   - A loading spinner shows progress
   - Processing typically takes 3-8 seconds

3. **View Summary**:
   - AI-generated summary appears in 1-2 paragraphs
   - Summary includes key points and main topics
   - Clean, formatted text without special characters

4. **Actions**:
   - **Copy Summary**: Click to copy text to clipboard
   - **Clear & Upload New**: Reset component for another file

### File Format Tips

**✅ Best Results:**
- Plain text (`.txt`) files
- Rich text format (`.rtf`) files

**⚠️ For Word/PDF Documents:**
1. Open your document
2. Select all text (Ctrl+A / Cmd+A)
3. Copy and paste into a new text file
4. Save as `.txt` format
5. Upload the text file

## ⚙️ Technical Details

### Apex Classes

- **FileSummarizerController**: Main controller handling file processing and AI API calls
- **FileSummarizerControllerTest**: Comprehensive test coverage (85%+)

### Key Methods

- `summarizeContentDocument()`: Main method for file processing and summarization
- `findRecentFileByName()`: Fallback method to locate uploaded files
- `getSupportedFileTypes()`: Returns list of supported file formats

### Lightning Web Component

- **Reactive Properties**: Real-time UI updates based on processing state
- **Error Handling**: User-friendly error messages and guidance
- **File Validation**: Client-side file type checking
- **Progressive Enhancement**: Graceful fallbacks for different scenarios

### AI Integration

- **Model**: `sfdc_ai__DefaultVertexAIGemini25Flash001`
- **Prompt**: Optimized for concise, clean summaries
- **Content Limits**: 10,000 character limit with truncation
- **Response Format**: 1-2 paragraphs, plain text only

## 🔒 Data & Storage

### File Storage
- **Location**: Salesforce standard file system (ContentDocument/ContentVersion)
- **Access**: Files tab in Salesforce org
- **Retention**: Files persist until manually deleted
- **Storage**: Counts against org file storage limits

### Summary Storage
- **Current**: Summaries are displayed temporarily (not stored)
- **Limitation**: Lost on page refresh or component reset
- **Future Enhancement**: Could be extended to store summaries in custom objects

## 🚧 Limitations

- **File Types**: Optimized for plain text; limited support for complex formats (Word, PDF)
- **File Size**: Large files may be truncated (10,000 character limit)
- **API Dependency**: Requires Salesforce AI Platform Models API access
- **No Summary History**: Summaries not permanently stored
- **Text Extraction**: Binary files and complex formatting not supported

## 🔮 Future Enhancements

- [ ] Summary history storage in custom objects
- [ ] Batch processing for multiple files
- [ ] Enhanced PDF/Word text extraction
- [ ] Custom prompt templates
- [ ] Summary comparison and versioning
- [ ] Integration with Salesforce Knowledge
- [ ] Automated categorization and tagging

## 🧪 Testing

Run tests in Salesforce:

```bash
# Run all tests
sfdx force:apex:test:run

# Run specific test class
sfdx force:apex:test:run -t FileSummarizerControllerTest
```

Test coverage: **85%+** (required for deployment)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Maintain test coverage above 85%
- Follow Salesforce coding standards
- Update documentation for new features
- Test on multiple file types and edge cases

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Common Issues

**"File not found" error:**
- Wait longer between upload and processing
- Check file permissions
- Try uploading again

**"Unable to extract text" error:**
- Convert file to plain text (.txt) format
- Ensure file contains readable text content
- Check file isn't corrupted

**API errors:**
- Verify Salesforce AI Platform access
- Check org limits and quotas
- Contact Salesforce admin

### Getting Help

- Check Salesforce Debug Logs for detailed error information
- Review browser console for JavaScript errors
- Ensure proper permissions and API access

## 👥 Authors

- **Sage** - *Initial work* - [GitHub Profile](https://github.com/ssmaddux)

## 🙏 Acknowledgments

- Salesforce AI Platform team for the Models API
- Salesforce community for Lightning Web Component resources
- OpenAI/Google for the underlying AI model technology

---

**Made with ❤️ for the Salesforce community**
