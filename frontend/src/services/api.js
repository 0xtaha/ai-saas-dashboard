import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL;

// Create axios instance with default config
const api = axios.create({
  baseURL: API_URL,
});

// Add token to requests if it exists
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    // Set Content-Type to application/json for non-FormData requests
    // For FormData, delete Content-Type to let browser set it with boundary
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    } else {
      config.headers['Content-Type'] = 'application/json';
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Handle response errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear token and redirect to login if unauthorized
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  register: async (username, email, password) => {
    const response = await api.post('/auth/register', { username, email, password });
    return response.data;
  },

  login: async (email, password) => {
    const response = await api.post('/auth/login', { email, password });
    if (response.data.data?.access_token) {
      localStorage.setItem('token', response.data.data.access_token);
    }
    return response.data;
  },

  logout: async () => {
    try {
      await api.post('/auth/logout');
    } finally {
      localStorage.removeItem('token');
    }
  },
};

// Files API
export const filesAPI = {
  upload: async (file, onProgress) => {
    console.log('Uploading file:', file.name, 'Type:', file.type, 'Size:', file.size);

    const formData = new FormData();
    // Append file - the File object already contains the MIME type
    formData.append('file', file, file.name);

    // Log FormData contents for debugging
    console.log('FormData entries:');
    for (let pair of formData.entries()) {
      console.log(pair[0], pair[1]);
    }

    // Don't set Content-Type header manually - let axios set it with the boundary
    const response = await api.post('/files/upload', formData, {
      onUploadProgress: (progressEvent) => {
        if (onProgress && progressEvent.total) {
          const percentCompleted = Math.round(
            (progressEvent.loaded * 100) / progressEvent.total
          );
          onProgress(percentCompleted);
        }
      },
    });
    return response.data;
  },

  list: async (page = 1, perPage = 20) => {
    const response = await api.get('/files/', {
      params: { page, per_page: perPage },
    });
    return response.data;
  },

  getFile: async (checksum) => {
    const response = await api.get(`/files/${checksum}`);
    return response.data;
  },

  deleteFile: async (checksum) => {
    const response = await api.delete(`/files/${checksum}`);
    return response.data;
  },

  getProcessingStatus: async (checksum) => {
    const response = await api.get(`/files/${checksum}/processing-status`);
    return response.data;
  },
};

export default api;
