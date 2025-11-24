import React, { useEffect, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import api from '../../api';
import './NavBar.css';
import { getUserName, subscribeUserName } from '../../auth';

const NavBar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isModerator, setIsModerator] = useState(false);
  const [username, setUsername] = useState<string | null>(getUserName());

  const fetchUserType = async () => {
    try {
      const response = await api.get('/Users/role');
      setIsAdmin(response.data.data[0].user_role === 'admin');
      setIsModerator(response.data.data[0].user_role === 'moderator');
    } catch (error) {
      console.error('Erro ao obter o tipo de usuário', error);
      setIsAdmin(false);
    }
  };

  useEffect(() => {
    if (location.pathname === '/productList') {
      fetchUserType();
    }
  }, [location.pathname]);

  useEffect(() => {
    const unsubscribe = subscribeUserName((name) => setUsername(name));
    return () => unsubscribe();
  }, []);

  const hideNavBar = location.pathname === '/dashboard' || location.pathname === '/login' || location.pathname === '/register';

  if (hideNavBar) {
    return null;
  }

  return (
    <header className="header">
      <div className="logo">Ark One{username ? ` ☀️ ${username}` : ''}</div>
      <nav>
        <div className="nav-buttons">
          {(location.pathname === '/register' || location.pathname === '/') && (
            <button className="btn btn-secondary" onClick={() => navigate('/login')}>
              Login
            </button>
          )}
          {(location.pathname === '/login' || location.pathname === '/') && (
            <button className="btn btn-primary" onClick={() => navigate('/register')}>
              Se Cadastrar
            </button>
          )}
          {isAdmin && location.pathname === '/productList' && (
            <button className="btn btn-primary" onClick={() => navigate('/registerProduct')}>
              Cadastrar Produto
            </button>
          )}
          {(isModerator || isAdmin) && location.pathname === '/productList' && (
            <button className="btn btn-primary" onClick={() => navigate('/registerAnalyst')}>
              Cadastrar Analista
            </button>
          )}
          {isAdmin && location.pathname === '/registerProduct' && (
            <button className="btn btn-primary" onClick={() => navigate('/registerCategory')}>
              Cadastrar Nova Categoria
            </button>
          )}
          {location.pathname !== '/' && location.pathname !== '/login' && location.pathname !== '/register' && (
            <button className="btn btn-secondary" onClick={() => navigate(-1)}>
              Voltar
            </button>
          )}
          {location.pathname !== '/' && location.pathname !== '/login' && location.pathname !== '/register' && (
            <button className="btn btn-primary" onClick={() => navigate('/')}>
              Sair
            </button>
          )}
        </div>
      </nav>
    </header>
  );
};

export default NavBar;
