import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import FileUpload from '../components/FileUpload';
import FileList from '../components/FileList';
import ProcessingResults from '../components/ProcessingResults';
import '../styles/Dashboard.css';

const Dashboard = () => {
  const { user, logout } = useAuth();
  const [refreshFiles, setRefreshFiles] = useState(0);
  const [selectedFile, setSelectedFile] = useState(null);

  const handleUploadSuccess = (data) => {
    // Refresh file list when upload succeeds
    setRefreshFiles((prev) => prev + 1);

    // Set selected file to show processing results
    if (data.file) {
      setSelectedFile(data);
    }
  };

  const handleLogout = async () => {
    await logout();
  };

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <div className="header-content">
          <h1>AI SaaS Dashboard</h1>
          <div className="header-actions">
            <span className="user-info">
              Welcome, {user?.username || 'User'}
            </span>
            <button onClick={handleLogout} className="btn btn-secondary">
              Logout
            </button>
          </div>
        </div>
      </header>

      <main className="dashboard-main">
        <div className="dashboard-grid">
          <section className="upload-section">
            <h2>Upload File</h2>
            <FileUpload onUploadSuccess={handleUploadSuccess} />
          </section>

          {selectedFile && (
            <section className="results-section">
              <ProcessingResults data={selectedFile} />
            </section>
          )}
        </div>

        <section className="files-section">
          <FileList refreshTrigger={refreshFiles} />
        </section>
      </main>
    </div>
  );
};

export default Dashboard;
