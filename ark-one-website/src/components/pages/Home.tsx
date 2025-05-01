import React from 'react';
import { Container, Button, Typography, Box, Stack } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import loadingGif from '../assets/background/sol-placa2.gif';

const Home: React.FC = () => {
  const navigate = useNavigate();

  const goToLogin = () => {
    navigate('/login');
  };

  const goToRegister = () => {
    navigate('/register');
  };

  return (
    <Container maxWidth="md">
      <Box 
        textAlign="center" 
        mt={5}
        sx={{
          color: 'black',
          backgroundColor: 'rgba(255, 255, 255, 0.6)',
          borderRadius: 2,
          padding: 3,
          boxShadow: 10
        }}
      >
        <Typography variant="h3" gutterBottom sx={{ fontWeight: 'bold', color: 'black' }}>
          Bem-vindo ao Ark One
        </Typography>
        <Typography variant="h6" color="textSecondary" gutterBottom sx={{ color: 'black' }}>
          Acesse para ver nossos produtos, ter acesso a dashboards e explorar mais!
        </Typography>
        <Box mt={4}>
          <Stack direction="row" spacing={2} justifyContent="center">
            <Button 
              variant="contained" 
              sx={{ 
                backgroundColor: '#007bff',
                color: 'white',
                '&:hover': { backgroundColor: '#0056b3' }
              }} 
              onClick={goToLogin}
            >
              Ir para Login
            </Button>
            <Button 
              variant="contained" 
              sx={{ 
                backgroundColor: '#28a745',
                color: 'white',
                '&:hover': { backgroundColor: '#218838' }
              }} 
              onClick={goToRegister}
            >
              Se Cadastrar
            </Button>
          </Stack>
        </Box>
        <Box mt={4} display="flex" justifyContent="center">
          <img 
              src={loadingGif}
              alt="Loading Animation" 
              style={{ width: '150px', height: 'auto' }} 
          />
        </Box>
      </Box>
    </Container>
  );
};

export default Home;
