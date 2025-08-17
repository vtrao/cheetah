import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [backendStatus, setBackendStatus] = useState('checking...');
  const [items, setItems] = useState([]);

  useEffect(() => {
    // Check backend health
    fetch('/api/health')
      .then(response => response.json())
      .then(data => {
        setBackendStatus(data.status || 'healthy');
      })
      .catch(error => {
        console.error('Backend health check failed:', error);
        setBackendStatus('error');
      });

    // Fetch items from backend
    fetch('/api/items')
      .then(response => response.json())
      .then(data => {
        setItems(data || []);
      })
      .catch(error => {
        console.error('Failed to fetch items:', error);
      });
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Cheetah Application Template</h1>
        <p>Backend Status: <span className={`status ${backendStatus}`}>{backendStatus}</span></p>
        
        <div className="items-section">
          <h2>Items from Backend</h2>
          {items.length > 0 ? (
            <ul>
              {items.map((item, index) => (
                <li key={index}>
                  <strong>{item.name}</strong> - {item.description}
                </li>
              ))}
            </ul>
          ) : (
            <p>No items found or backend not responding</p>
          )}
        </div>

        <div className="info-section">
          <h2>Template Features</h2>
          <ul className="feature-list">
            <li>✅ React 18 with Hooks</li>
            <li>✅ Backend API Integration</li>
            <li>✅ Health Check Monitoring</li>
            <li>✅ Docker Ready</li>
            <li>✅ Kubernetes Compatible</li>
            <li>✅ Nginx Proxy Configuration</li>
          </ul>
        </div>
      </header>
    </div>
  );
}

export default App;
