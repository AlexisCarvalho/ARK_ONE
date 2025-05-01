import React, { useState } from 'react';
import { Container, TextField, Button, Typography, Box } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api';

const Register: React.FC = () => {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [nameError, setNameError] = useState('');
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [registrationError, setRegistrationError] = useState('');
  const navigate = useNavigate();

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setNameError('');
    setEmailError('');
    setPasswordError('');
    setRegistrationError('');

    if (!name && !email && !password) {
      setRegistrationError("Nome, Email e Senha são obrigatórios");
    } else {
      if (!name) {
        setNameError('Nome é obrigatório');
      }
      if (!email) {
        setEmailError('Email é obrigatório');
      }
      if (!password) {
        setPasswordError('Senha é obrigatória');
      }
    }

    if (name && email && password) {
      try {
        await api.post('Account/register', { name, email, password });
        navigate('/login');
      } catch (error) {
        setRegistrationError('Falha ao registrar. O Email pode já estar em uso.');
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
          Registrar
        </Typography>
        
        <TextField 
          label="Nome" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={name} 
          onChange={(e) => setName(e.target.value)} 
          error={!!nameError || !!registrationError}
          onFocus={() => { setNameError(''); setRegistrationError(''); }}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />
        
        <TextField 
          label="Email" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={email} 
          onChange={(e) => setEmail(e.target.value)} 
          error={!!emailError || !!registrationError}
          onFocus={() => { setEmailError(''); setRegistrationError(''); }}
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
          error={!!passwordError || !!registrationError}
          onFocus={() => { setPasswordError(''); setRegistrationError(''); }}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />
        
        <Box sx={{ mt: 2 }}>
          {nameError && (
            <Typography variant="body2" color="error">{nameError}</Typography>
          )}
          {emailError && (
            <Typography variant="body2" color="error">{emailError}</Typography>
          )}
          {passwordError && (
            <Typography variant="body2" color="error">{passwordError}</Typography>
          )}
          {registrationError && (
            <Typography variant="body2" color="error">{registrationError}</Typography>
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
          onClick={handleRegister}
        >
          Registrar
        </Button>
      </Box>
    </Container>
  );
};

export default Register;
