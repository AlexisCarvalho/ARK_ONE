import React, { useState } from 'react';
import { Container, TextField, Button, Typography, Box } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api';
import { setAuthToken } from '../../auth';

const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [credentialsError, setCredentialsError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setEmailError('');
    setPasswordError('');
    setCredentialsError('');

    if (!email && !password) {
      setCredentialsError("Email e Senha Obrigatórios");
    } else {
      if (!email) {
        setEmailError('Email é obrigatório');
      }
      if (!password) {
        setPasswordError('Senha é obrigatória');
      }
    }

    if (email && password) {
      try {
        const response = await api.post('Account/login', { email, password });
        setAuthToken(response.data.token);
        navigate('/products', {
          state: {
            previousLocation: window.location.pathname,
          }
        });
      } catch (error) {
        setCredentialsError('Login falhou. Senha ou Email Incorretos.');
      }
    }
  };

  return (
    <Container maxWidth="xs">
      <Box 
        textAlign="center" 
        mt={5}
        sx={{
          backgroundColor: 'rgba(255, 255, 255, 0.6)',
          borderRadius: 2,
          padding: 4,
          boxShadow: 10,
          color: 'black'
        }}
      >
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
          Login
        </Typography>
        
        <TextField 
          label="Email" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={email} 
          onChange={(e) => setEmail(e.target.value)} 
          error={!!emailError || !!credentialsError}
          onFocus={() => { setEmailError(''); setCredentialsError(''); }}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />
        
        <TextField 
          label="Senha" 
          type="password" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={password} 
          onChange={(e) => setPassword(e.target.value)} 
          error={!!passwordError || !!credentialsError}
          onFocus={() => { setPasswordError(''); setCredentialsError(''); }}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />
        
        <Box sx={{ mt: 2 }}>
          {emailError && (
            <Typography variant="body2" color="error">{emailError}</Typography>
          )}
          {passwordError && (
            <Typography variant="body2" color="error">{passwordError}</Typography>
          )}
          {credentialsError && (
            <Typography variant="body2" color="error">{credentialsError}</Typography>
          )}
        </Box>

        <Button 
          variant="contained" 
          fullWidth 
          sx={{ 
            mt: 2, 
            backgroundColor: '#007bff',
            '&:hover': { backgroundColor: '#0056b3' }
          }} 
          onClick={handleLogin}
        >
          Entrar
        </Button>
        
        <Box mt={4} display="flex" justifyContent="center">
        </Box>
      </Box>
    </Container>
  );
};

export default Login;
