"""
Basic tests for SimpleTimeService
"""
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_root_endpoint_returns_200():
    """Test that root endpoint returns 200 status"""
    response = client.get("/")
    assert response.status_code == 200

def test_root_endpoint_returns_json():
    """Test that root endpoint returns valid JSON"""
    response = client.get("/")
    data = response.json()
    assert "timestamp" in data
    assert "ip" in data

def test_timestamp_format():
    """Test that timestamp is in ISO format"""
    response = client.get("/")
    data = response.json()
    timestamp = data["timestamp"]
    # Basic check that it looks like ISO format
    assert "T" in timestamp
    assert len(timestamp) > 20

def test_ip_is_string():
    """Test that IP is returned as string"""
    response = client.get("/")
    data = response.json()
    assert isinstance(data["ip"], str)

