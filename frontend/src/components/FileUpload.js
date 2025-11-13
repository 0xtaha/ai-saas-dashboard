import React, { useState } from 'react';
import { filesAPI } from '../services/api';
import '../styles/FileUpload.css';

const FileUpload = ({ onUploadSuccess }) => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleFileSelect = (e) => {
    const file = e.target.files[0];
    setSelectedFile(file);
    setError('');
    setSuccess('');
    setUploadProgress(0);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    setSelectedFile(file);
    setError('');
    setSuccess('');
  };

  const handleDragOver = (e) => {
    e.preventDefault();
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  const handleUpload = async () => {
    if (!selectedFile) {
      setError('Please select a file first');
      return;
    }

    setUploading(true);
    setError('');
    setSuccess('');

    try {
      const response = await filesAPI.upload(
        selectedFile,
        (progress) => setUploadProgress(progress)
      );

      // Backend returns { status: "success", data: {...}, message: "..." }
      if (response.status === 'success') {
        setSuccess('File uploaded successfully!');
        setSelectedFile(null);
        setUploadProgress(0);

        // Call parent callback if provided
        if (onUploadSuccess) {
          onUploadSuccess(response.data);
        }

        // Reset file input
        document.getElementById('file-input').value = '';
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Upload failed');
      setUploadProgress(0);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="file-upload-container">
      <div
        className="drop-zone"
        onDrop={handleDrop}
        onDragOver={handleDragOver}
      >
        <input
          type="file"
          id="file-input"
          onChange={handleFileSelect}
          disabled={uploading}
          className="file-input"
          accept=".txt,.pdf,.png,.jpg,.jpeg,.gif,.doc,.docx,.csv,.xlsx"
        />
        <label htmlFor="file-input" className="drop-zone-label">
          <div className="upload-icon">📁</div>
          <p className="drop-zone-text">
            {selectedFile
              ? selectedFile.name
              : 'Drag and drop a file here or click to select'}
          </p>
          {selectedFile && (
            <p className="file-size">{formatFileSize(selectedFile.size)}</p>
          )}
        </label>
      </div>

      {selectedFile && (
        <button
          onClick={handleUpload}
          disabled={uploading}
          className="btn btn-primary upload-btn"
        >
          {uploading ? 'Uploading...' : 'Upload File'}
        </button>
      )}

      {uploading && (
        <div className="progress-container">
          <div className="progress-bar">
            <div
              className="progress-fill"
              style={{ width: `${uploadProgress}%` }}
            ></div>
          </div>
          <p className="progress-text">{uploadProgress}%</p>
        </div>
      )}

      {error && <div className="error-message">{error}</div>}
      {success && <div className="success-message">{success}</div>}
    </div>
  );
};

export default FileUpload;
