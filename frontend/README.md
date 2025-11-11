# AI SaaS Dashboard - Frontend

A modern React-based frontend application for the AI SaaS Dashboard platform with file upload, processing, and results visualization.

## Features

- **User Authentication**
  - Register new account
  - Login with email and password
  - JWT-based authentication
  - Protected routes

- **File Management**
  - Drag-and-drop file upload
  - File validation (type and size)
  - Real-time upload progress
  - File list with pagination
  - Delete files
  - Duplicate detection via checksum

- **AI Processing**
  - Automatic file processing on upload
  - Processing status tracking
  - Results display (with mock data)
  - Processing history

- **User Interface**
  - Responsive design
  - Clean, modern UI
  - Loading states and error handling
  - Smooth animations and transitions

## Tech Stack

- **React 18** - UI library
- **React Router 6** - Client-side routing
- **Axios** - HTTP client
- **Context API** - State management
- **CSS3** - Styling

## Prerequisites

- Node.js (version 14 or higher)
- npm or yarn
- Backend API running (see backend README)

## Installation

### 1. Navigate to the frontend directory

```bash
cd frontend
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure environment variables

Create a `.env` file in the frontend directory:

```bash
cp .env.example .env
```

Edit `.env` and set the backend API URL:

```
REACT_APP_API_URL=http://localhost:5000/api
```

## Running the Application

### Development Mode

Start the development server with hot reload:

```bash
npm start
```

The application will open at `http://localhost:3000`

### Production Build

Create an optimized production build:

```bash
npm run build
```

The build files will be in the `build/` directory.

### Running Tests

```bash
npm test
```

## Project Structure

```
frontend/
├── public/
│   └── index.html              # HTML template
├── src/
│   ├── components/             # React components
│   │   ├── FileUpload.js       # File upload component
│   │   ├── FileList.js         # Files list component
│   │   ├── ProcessingResults.js # Results display
│   │   └── PrivateRoute.js     # Route protection
│   ├── contexts/               # React contexts
│   │   └── AuthContext.js      # Authentication context
│   ├── pages/                  # Page components
│   │   ├── Login.js            # Login page
│   │   ├── Register.js         # Registration page
│   │   └── Dashboard.js        # Main dashboard
│   ├── services/               # API services
│   │   └── api.js              # API client and endpoints
│   ├── styles/                 # CSS files
│   │   ├── index.css
│   │   ├── App.css
│   │   ├── Auth.css
│   │   ├── Dashboard.css
│   │   ├── FileUpload.css
│   │   ├── FileList.css
│   │   └── ProcessingResults.css
│   ├── App.js                  # Main App component
│   └── index.js                # Entry point
├── .env                        # Environment variables
├── .env.example                # Example environment file
├── package.json                # Dependencies
└── README.md                   # This file
```

## Usage Guide

### 1. Register an Account

1. Navigate to `http://localhost:3000`
2. Click "Register here" on the login page
3. Fill in:
   - Username (min 3 characters)
   - Email
   - Password (min 8 characters)
   - Confirm Password
4. Click "Register"
5. You'll be redirected to the login page

### 2. Login

1. Enter your email and password
2. Click "Login"
3. You'll be redirected to the dashboard

### 3. Upload Files

1. On the dashboard, use the file upload section
2. Either:
   - Click to select a file
   - Drag and drop a file
3. Supported file types: txt, pdf, png, jpg, jpeg, gif, doc, docx, csv, xlsx
4. Maximum file size: 16 MB (configurable in backend)
5. Click "Upload File"
6. Watch the upload progress
7. View processing results

### 4. View Files

- All uploaded files are listed below the upload section
- See file details: name, size, type, upload date, checksum
- Check processing status (Processing/Processed)
- Delete files you no longer need

### 5. Processing Results

When a file is uploaded:
- It's automatically sent to the AI server for processing
- Processing status is shown in real-time
- Mock results are displayed (until backend AI is fully configured)
- Results include:
  - Summary
  - Key statistics
  - Keywords
  - Detected entities

## API Endpoints Used

The frontend communicates with these backend endpoints:

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/profile` - Get user profile

### Files
- `POST /api/files/upload` - Upload file
- `GET /api/files/` - List files (paginated)
- `GET /api/files/:checksum` - Get file details
- `DELETE /api/files/:checksum` - Delete file
- `GET /api/files/:checksum/processing-status` - Get processing status

## Configuration

### Environment Variables

- `REACT_APP_API_URL` - Backend API base URL (default: `http://localhost:5000/api`)

### Customization

**To change allowed file types**, edit `FileUpload.js`:
```javascript
accept=".txt,.pdf,.png,.jpg,.jpeg,.gif,.doc,.docx,.csv,.xlsx"
```

**To modify pagination**, edit the API call in `FileList.js`:
```javascript
const response = await filesAPI.list(page, 20); // 20 = items per page
```

## Troubleshooting

### CORS Errors
If you see CORS errors, ensure the backend is configured to allow requests from `http://localhost:3000`:
```python
CORS_ORIGINS=http://localhost:3000
```

### API Connection Failed
1. Verify backend is running on `http://localhost:5000`
2. Check `.env` file has correct `REACT_APP_API_URL`
3. Ensure no firewall is blocking the connection

### Authentication Issues
1. Clear browser localStorage: `localStorage.clear()`
2. Check browser console for error messages
3. Verify backend JWT configuration

### File Upload Fails
1. Check file size is under limit (16 MB default)
2. Verify file type is allowed
3. Check backend logs for errors
4. Ensure `uploaded_files` directory exists and is writable

## Development Tips

### Adding New Routes
1. Create component in `src/pages/`
2. Add route in `App.js`
3. Use `<PrivateRoute>` for protected routes

### Adding New API Endpoints
1. Add function to `src/services/api.js`
2. Use the `api` axios instance for automatic auth header injection

### Styling
- Global styles in `src/styles/App.css`
- Component-specific styles in separate CSS files
- Uses BEM-like naming convention

## Mock Data

The application includes mock processing results for demonstration:
- Summary text
- Keywords extraction
- Entity detection
- Sentiment analysis
- Statistics

These are shown when the actual backend AI processing is not available. Once the backend is fully configured, real results will replace the mock data.

## Building for Production

1. Update `.env` with production API URL
2. Build the application:
   ```bash
   npm run build
   ```
3. Deploy the `build/` folder to your hosting service:
   - Netlify
   - Vercel
   - AWS S3 + CloudFront
   - Any static hosting service

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## License

MIT
