import React from 'react';
import MapComponent from '../maps/MapComponent';
import { Container, Typography, Box } from '@mui/material';
import 'leaflet/dist/leaflet.css';

const SetLocationMap: React.FC = () => {
  return (
    <Container maxWidth="md">
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
          Localização do Dispositivo
        </Typography>
        <MapComponent />
      </Box>
    </Container>
  );
};

export default SetLocationMap;
