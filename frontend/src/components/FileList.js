import React, { useState, useEffect } from 'react';
import { filesAPI } from '../services/api';
import '../styles/FileList.css';

const FileList = ({ refreshTrigger, onFileSelect }) => {
  const [files, setFiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [pagination, setPagination] = useState({
    page: 1,
    per_page: 20,
    total: 0,
    pages: 0,
  });

  useEffect(() => {
    loadFiles();
  }, [refreshTrigger]);

  const loadFiles = async (page = 1) => {
    setLoading(true);
    setError('');

    try {
      const response = await filesAPI.list(page, 20);
      console.log('=== FILES API DEBUG ===');
      console.log('Full response:', JSON.stringify(response, null, 2));
      console.log('response.status:', response.status);
      console.log('response.data:', response.data);
      console.log('response.data.files:', response.data?.files);
      console.log('Files array length:', response.data?.files?.length);

      // Backend returns { status: "success", data: {...}, message: "..." }
      if (response.status === 'success') {
        const filesList = response.data.files || [];
        console.log('Setting files to state:', filesList);
        console.log('Number of files:', filesList.length);
        setFiles(filesList);
        setPagination(response.data.pagination || pagination);
      } else {
        console.log('Response not successful:', response.message);
        setError(response.message || 'Failed to load files');
      }
    } catch (err) {
      console.error('Error loading files:', err);
      const errorMsg = err.response?.data?.message || err.message || 'Failed to load files';
      setError(errorMsg);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (checksum) => {
    if (!window.confirm('Are you sure you want to delete this file?')) {
      return;
    }

    try {
      await filesAPI.deleteFile(checksum);
      loadFiles(pagination.page);
    } catch (err) {
      alert('Failed to delete file');
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  const getStatusBadge = (isProcessed) => {
    return isProcessed ? (
      <span className="badge badge-success">Processed</span>
    ) : (
      <span className="badge badge-warning">Processing</span>
    );
  };

  console.log('FileList render - loading:', loading, 'files count:', files.length, 'error:', error);

  if (loading && files.length === 0) {
    return <div className="loading">Loading files...</div>;
  }

  return (
    <div className="file-list-container">
      <h2>Your Files</h2>

      {error && <div className="error-message">{error}</div>}

      {files.length === 0 ? (
        <div className="empty-state">
          <p>No files uploaded yet. Upload your first file above!</p>
        </div>
      ) : (
        <>
          <div className="file-list">
            {files.map((file) => (
              <div
                key={file.checksum}
                className="file-item"
                onClick={() => onFileSelect && onFileSelect(file)}
                style={{ cursor: onFileSelect ? 'pointer' : 'default' }}
              >
                <div className="file-info">
                  <div className="file-icon">📄</div>
                  <div className="file-details">
                    <h3 className="file-name">{file.filename}</h3>
                    <div className="file-meta">
                      <span>{formatFileSize(file.size)}</span>
                      <span className="separator">•</span>
                      <span>{file.mime_type || 'Unknown type'}</span>
                      <span className="separator">•</span>
                      <span>{formatDate(file.uploaded_at)}</span>
                    </div>
                    <div className="file-checksum">
                      Checksum: {file.checksum.substring(0, 16)}...
                    </div>
                    {file.processing_result && (
                      <div className="file-result-preview">
                        <small>✓ Analysis available - Click to view</small>
                      </div>
                    )}
                  </div>
                </div>
                <div className="file-actions">
                  {getStatusBadge(file.is_processed)}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDelete(file.checksum);
                    }}
                    className="btn btn-danger btn-sm"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
          </div>

          {pagination.pages > 1 && (
            <div className="pagination">
              <button
                onClick={() => loadFiles(pagination.page - 1)}
                disabled={pagination.page === 1}
                className="btn btn-secondary"
              >
                Previous
              </button>
              <span className="page-info">
                Page {pagination.page} of {pagination.pages}
              </span>
              <button
                onClick={() => loadFiles(pagination.page + 1)}
                disabled={pagination.page === pagination.pages}
                className="btn btn-secondary"
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default FileList;
