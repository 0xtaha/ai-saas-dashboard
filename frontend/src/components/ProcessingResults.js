import React from 'react';
import '../styles/ProcessingResults.css';

const ProcessingResults = ({ data }) => {
  const { file, ai_processing } = data;

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
                <div className="result-box">
                  <h5>AI Processing Result</h5>
                  <div className="result-text">
                    {typeof file.processing_result === 'string' ? (
                      <p>{file.processing_result}</p>
                    ) : (
                      <pre>{JSON.stringify(file.processing_result, null, 2)}</pre>
                    )}
                  </div>
                </div>
                {file.processed_at && (
                  <div className="processed-time">
                    <small>Processed at: {new Date(file.processed_at).toLocaleString()}</small>
                  </div>
                )}
              </div>
            ) : (
              <div className="no-results">
                <p>⏳ File is queued for processing. Results will appear here once processing is complete.</p>
                <p className="help-text">The AI service is analyzing your file. This may take a few moments.</p>
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
