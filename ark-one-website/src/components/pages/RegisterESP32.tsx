import React, { useEffect, useState, useRef } from 'react';
import { Container, TextField, Button, Typography, Box } from '@mui/material';
import { Html5QrcodeScanner } from 'html5-qrcode';
import { useNavigate, useLocation } from 'react-router-dom';
import api from '../../api';

const RegisterESP32: React.FC = () => {
  const [esp32Id, setEsp32Id] = useState('');
  const [error, setError] = useState('');
  const qrCodeRef = useRef<HTMLDivElement | null>(null);
  const navigate = useNavigate();
  const location = useLocation();
  const id_product = location.state?.id_product;

  useEffect(() => {
    if (!id_product) {
      setError('Produto não especificado.');
    }
  }, [id_product]);

  useEffect(() => {
    if (qrCodeRef.current) {
      const scanner = new Html5QrcodeScanner(
        "qrCodeScanner",
        {
          fps: 10,
          qrbox: 250,
        },
        false
      );

      scanner.render(onScanSuccess, onScanError);

      return () => {
        scanner.clear().catch((err) => console.error('Erro ao limpar scanner:', err));
      };
    }
  }, []);

  const onScanSuccess = (decodedText: string, decodedResult: any) => {
    setEsp32Id(decodedText);
  };

  const onScanError = (error: any) => {
    console.error(`Erro no scanner QR: ${error}`);
  };

  const handleRegister = async () => {
    if (!id_product) {
      setError('Produto não especificado.');
      return;
    }

    if (!esp32Id) {
      setError('O ESP32 ID é obrigatório ou não foi lido corretamente do QR Code.');
      return;
    }

    try {
      await api.post('/Person/products/register', {
        id_product,
        esp32_unique_id: esp32Id,
      });

      navigate('/specificPurchasedProduct', { state: { id_product } });
    } catch (err) {
      setError('Falha ao registrar o dispositivo. O mesmo pode já estar cadastrado.');
      console.error(err);
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
          color: 'black',
        }}
      >
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
          Registrar Dispositivo ESP32
        </Typography>

        <div
          id="qrCodeScanner"
          ref={qrCodeRef}
          style={{
            width: '100%',
            height: 'auto',
            borderRadius: '10px',
            border: '2px solid #007bff',
            boxShadow: '0px 4px 10px rgba(0, 0, 0, 0.1)',
            marginBottom: '20px',
          }}
        ></div>

        <TextField
          label="ESP32 ID"
          variant="filled"
          fullWidth
          margin="normal"
          color="primary"
          value={esp32Id}
          onChange={(e) => setEsp32Id(e.target.value)}
          error={!!error}
          onFocus={() => setError('')}
          sx={{
            input: { color: 'black' },
            bgcolor: 'rgba(255, 255, 255, 0.8)',
            borderRadius: 1,
          }}
        />

        {error && (
          <Typography variant="body2" color="error" sx={{ mt: 2 }}>
            {error}
          </Typography>
        )}

        <Button
          variant="contained"
          fullWidth
          sx={{
            mt: 2,
            backgroundColor: '#007bff',
            '&:hover': { backgroundColor: '#0056b3' },
            padding: '12px 16px',
            borderRadius: '8px',
            fontWeight: 'bold',
            fontSize: '16px',
          }}
          onClick={handleRegister}
        >
          Registrar
        </Button>
      </Box>
    </Container>
  );
};

export default RegisterESP32;
