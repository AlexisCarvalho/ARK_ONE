import React, { useEffect, useState } from 'react';
import { AppBar, Toolbar, Button, Typography, Box } from '@mui/material';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import api from '../../api';

const NavBar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);

  const fetchUserType = async () => {
    try {
      const response = await api.get('/Person/getType');
      setIsAdmin(response.data.data[0] === 'admin');
    } catch (error) {
      console.error('Erro ao obter o tipo de usuário', error);
      setIsAdmin(false);
    }
  };

  useEffect(() => {
    if (location.pathname === '/products') {
      fetchUserType();
    }
  }, [location.pathname]);

  const isDashboard = location.pathname === '/dashboard';

  if (isDashboard) {
    return null;
  }

  const handleBackButtonClick = () => {
    const previousLocation = location.state?.previousLocation || '/products';
    navigate(previousLocation, { state: { additionalData: 'data to send' } });
  };

  return (
    <AppBar
      position="static"
      sx={{
        background: 'linear-gradient(90deg, #F85700, #FFA901)',
      }}
    >
      <Toolbar>
        <Typography variant="h6" sx={{ flexGrow: 1 }}>
          Ark One - Energia Renovável
        </Typography>
        <Box>
          {location.pathname === '/register' && (
            <Button color="inherit" component={Link} to="/login">
              Login
            </Button>
          )}
          {location.pathname === '/login' && (
            <Button color="inherit" component={Link} to="/register">
              Se Cadastrar
            </Button>
          )}
          {isAdmin && location.pathname === '/products' && (
            <Button color="inherit" component={Link} to="/registerProduct">
              Cadastrar Produto
            </Button>
          )}
          {isAdmin && location.pathname === '/registerProduct' && (
            <Button color="inherit" component={Link} to="/registerCategory">
              Cadastrar Nova Categoria
            </Button>
          )}
          {location.pathname !== '/' && location.pathname !== '/login' && location.pathname !== '/register' && location.pathname !== '/setLocationMap' && location.pathname !== '/products' && (
            <Button color="inherit" onClick={handleBackButtonClick}>
              Voltar
            </Button>
          )}
          {location.pathname !== '/' && location.pathname !== '/login' && location.pathname !== '/register' && (
            <Button color="inherit" component={Link} to="/">
              Sair
            </Button>
          )}
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default NavBar;
