import React from 'react';
import '../styles/ProcessingResults.css';

const ProcessingResults = ({ data }) => {
  const { file, ai_processing } = data;

  // Mock data for demonstration when backend isn't fully connected
  const mockResults = {
    summary: "This is a mock summary of the processed file. The AI has analyzed the content and extracted key information.",
    keywords: ["document", "analysis", "AI", "processing", "data"],
    sentiment: "Neutral",
    entities: [
      { type: "Person", value: "John Doe" },
      { type: "Organization", value: "AI Corp" },
      { type: "Date", value: "2024-01-15" }
    ],
    textLength: 1250,
    language: "English"
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed':
        return 'success';
      case 'processing':
        return 'warning';
      case 'failed':
        return 'danger';
      case 'already_processed':
        return 'info';
      default:
        return 'secondary';
    }
  };

  return (
    <div className="processing-results">
      <h2>Processing Results</h2>

      <div className="result-card">
        <div className="result-header">
          <h3>{file.filename}</h3>
          <span className={`badge badge-${getStatusColor(ai_processing.status)}`}>
            {ai_processing.status.replace('_', ' ').toUpperCase()}
          </span>
        </div>

        <div className="result-info">
          <div className="info-item">
            <strong>Checksum:</strong>
            <span className="monospace">{file.checksum.substring(0, 32)}...</span>
          </div>
          <div className="info-item">
            <strong>Size:</strong>
            <span>{(file.size / 1024).toFixed(2)} KB</span>
          </div>
          <div className="info-item">
            <strong>Type:</strong>
            <span>{file.mime_type || 'Unknown'}</span>
          </div>
          <div className="info-item">
            <strong>Uploaded:</strong>
            <span>{new Date(file.uploaded_at).toLocaleString()}</span>
          </div>
        </div>

        {ai_processing.status === 'processing' && (
          <div className="processing-status">
            <div className="spinner"></div>
            <p>AI is processing your file...</p>
            <p className="status-message">{ai_processing.message}</p>
          </div>
        )}

        {ai_processing.status === 'failed' && (
          <div className="error-status">
            <p>❌ Processing failed</p>
            <p className="error-details">{ai_processing.message}</p>
          </div>
        )}

        {(ai_processing.status === 'completed' || ai_processing.status === 'already_processed') && (
          <div className="results-content">
            <h4>Analysis Results</h4>

            {file.processing_result ? (
              <div className="actual-results">
                <pre>{file.processing_result}</pre>
              </div>
            ) : (
              <div className="mock-results">
                <div className="results-section">
                  <h5>Summary</h5>
                  <p>{mockResults.summary}</p>
                </div>

                <div className="results-section">
                  <h5>Key Statistics</h5>
                  <div className="stats-grid">
                    <div className="stat-item">
                      <span className="stat-label">Text Length</span>
                      <span className="stat-value">{mockResults.textLength} chars</span>
                    </div>
                    <div className="stat-item">
                      <span className="stat-label">Language</span>
                      <span className="stat-value">{mockResults.language}</span>
                    </div>
                    <div className="stat-item">
                      <span className="stat-label">Sentiment</span>
                      <span className="stat-value">{mockResults.sentiment}</span>
                    </div>
                  </div>
                </div>

                <div className="results-section">
                  <h5>Keywords</h5>
                  <div className="keywords">
                    {mockResults.keywords.map((keyword, index) => (
                      <span key={index} className="keyword-badge">
                        {keyword}
                      </span>
                    ))}
                  </div>
                </div>

                <div className="results-section">
                  <h5>Detected Entities</h5>
                  <div className="entities">
                    {mockResults.entities.map((entity, index) => (
                      <div key={index} className="entity-item">
                        <span className="entity-type">{entity.type}:</span>
                        <span className="entity-value">{entity.value}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="mock-notice">
                  <p>ℹ️ These are mock results for demonstration. Connect to the AI backend to see real processing results.</p>
                </div>
              </div>
            )}
          </div>
        )}

        {ai_processing.request_id && (
          <div className="request-info">
            <small>Request ID: {ai_processing.request_id}</small>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProcessingResults;
