# Storage abstraction service for local and cloud storage
import os
from abc import ABC, abstractmethod
from typing import Tuple, Optional
from flask import current_app


class StorageBackend(ABC):
    """Abstract base class for storage backends"""

    @abstractmethod
    def save(self, file_data: bytes, filename: str) -> Tuple[bool, str, Optional[str]]:
        """
        Save file data to storage
        Returns: (success, message, storage_path)
        """
        pass

    @abstractmethod
    def delete(self, storage_path: str) -> Tuple[bool, str]:
        """
        Delete file from storage
        Returns: (success, message)
        """
        pass

    @abstractmethod
    def get_url(self, storage_path: str) -> str:
        """Get URL or path to access the file"""
        pass

    @abstractmethod
    def exists(self, storage_path: str) -> bool:
        """Check if file exists in storage"""
        pass


class LocalStorageBackend(StorageBackend):
    """Local filesystem storage backend"""

    def __init__(self, base_path: str = None):
        if base_path:
            self.base_path = base_path
        else:
            self.base_path = os.path.join(
                current_app.root_path,
                '..',
                'uploaded_files'
            )
        os.makedirs(self.base_path, exist_ok=True)

    def save(self, file_data: bytes, filename: str) -> Tuple[bool, str, Optional[str]]:
        """Save file to local filesystem"""
        try:
            filepath = os.path.join(self.base_path, filename)
            with open(filepath, 'wb') as f:
                f.write(file_data)
            return True, "File saved successfully", filepath
        except Exception as e:
            return False, f"Failed to save file: {str(e)}", None

    def delete(self, storage_path: str) -> Tuple[bool, str]:
        """Delete file from local filesystem"""
        try:
            if os.path.exists(storage_path):
                os.remove(storage_path)
                return True, "File deleted successfully"
            return False, "File not found"
        except Exception as e:
            return False, f"Failed to delete file: {str(e)}"

    def get_url(self, storage_path: str) -> str:
        """Get local file path"""
        return storage_path

    def exists(self, storage_path: str) -> bool:
        """Check if file exists locally"""
        return os.path.exists(storage_path)


class AzureBlobStorageBackend(StorageBackend):
    """Azure Blob Storage backend"""

    def __init__(self, connection_string: str = None, container_name: str = None):
        from azure.storage.blob import BlobServiceClient

        self.connection_string = connection_string or os.getenv('AZURE_STORAGE_CONNECTION_STRING')
        self.container_name = container_name or os.getenv('AZURE_STORAGE_CONTAINER', 'uploaded-files')

        if not self.connection_string:
            raise ValueError("Azure Storage connection string not configured")

        try:
            self.blob_service_client = BlobServiceClient.from_connection_string(
                self.connection_string
            )
            # Create container if it doesn't exist
            try:
                self.container_client = self.blob_service_client.get_container_client(
                    self.container_name
                )
                if not self.container_client.exists():
                    self.container_client.create_container()
            except Exception:
                self.container_client = self.blob_service_client.create_container(
                    self.container_name
                )
        except Exception as e:
            raise ValueError(f"Failed to initialize Azure Blob Storage: {str(e)}")

    def save(self, file_data: bytes, filename: str) -> Tuple[bool, str, Optional[str]]:
        """Save file to Azure Blob Storage"""
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=filename
            )
            blob_client.upload_blob(file_data, overwrite=True)
            blob_url = blob_client.url
            return True, "File uploaded to Azure Blob Storage", blob_url
        except Exception as e:
            return False, f"Failed to upload to Azure Blob Storage: {str(e)}", None

    def delete(self, storage_path: str) -> Tuple[bool, str]:
        """Delete file from Azure Blob Storage"""
        try:
            # Extract blob name from URL or use as-is
            if storage_path.startswith('http'):
                blob_name = storage_path.split('/')[-1]
            else:
                blob_name = storage_path

            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            blob_client.delete_blob()
            return True, "File deleted from Azure Blob Storage"
        except Exception as e:
            return False, f"Failed to delete from Azure Blob Storage: {str(e)}"

    def get_url(self, storage_path: str) -> str:
        """Get blob URL"""
        return storage_path

    def exists(self, storage_path: str) -> bool:
        """Check if blob exists"""
        try:
            if storage_path.startswith('http'):
                blob_name = storage_path.split('/')[-1]
            else:
                blob_name = storage_path

            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            return blob_client.exists()
        except Exception:
            return False


class StorageService:
    """Storage service that routes to appropriate backend"""

    _backend: Optional[StorageBackend] = None

    @classmethod
    def get_backend(cls) -> StorageBackend:
        """Get or create storage backend based on configuration"""
        if cls._backend is None:
            storage_type = os.getenv('STORAGE_TYPE', 'local').lower()

            if storage_type == 'azure':
                try:
                    cls._backend = AzureBlobStorageBackend()
                    current_app.logger.info("Using Azure Blob Storage backend")
                except Exception as e:
                    current_app.logger.error(f"Failed to initialize Azure Blob Storage: {e}")
                    current_app.logger.info("Falling back to local storage")
                    cls._backend = LocalStorageBackend()
            else:
                cls._backend = LocalStorageBackend()
                current_app.logger.info("Using local filesystem storage backend")

        return cls._backend

    @classmethod
    def save_file(cls, file_data: bytes, filename: str) -> Tuple[bool, str, Optional[str]]:
        """Save file using configured backend"""
        backend = cls.get_backend()
        return backend.save(file_data, filename)

    @classmethod
    def delete_file(cls, storage_path: str) -> Tuple[bool, str]:
        """Delete file using configured backend"""
        backend = cls.get_backend()
        return backend.delete(storage_path)

    @classmethod
    def get_file_url(cls, storage_path: str) -> str:
        """Get file URL"""
        backend = cls.get_backend()
        return backend.get_url(storage_path)

    @classmethod
    def file_exists(cls, storage_path: str) -> bool:
        """Check if file exists"""
        backend = cls.get_backend()
        return backend.exists(storage_path)
