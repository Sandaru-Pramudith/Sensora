from pathlib import Path

def test_backend_exists():
    assert Path("backend").exists()

def test_frontend_exists():
    assert Path("frontend").exists()