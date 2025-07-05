import React from 'react';
import { useAuth } from '../context/AuthContext';
import './Dashboard.css';

const Dashboard: React.FC = () => {
  const { user, logout } = useAuth();

  const handleLogout = () => {
    logout();
  };

  return (
    <div className="dashboard-container">
      <header className="dashboard-header">
        <h1>Panel de Control</h1>
        <div className="user-info">
          <span>Bienvenido, {user?.username}</span>
          <button onClick={handleLogout} className="logout-button">
            Cerrar Sesión
          </button>
        </div>
      </header>
      
      <main className="dashboard-content">
        <div className="welcome-card">
          <h2>¡Bienvenido al sistema!</h2>
          <p>Has iniciado sesión correctamente.</p>
          <div className="user-details">
            <p><strong>Usuario:</strong> {user?.username}</p>
            <p><strong>Email:</strong> {user?.email}</p>
            <p><strong>ID:</strong> {user?.id}</p>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Dashboard;