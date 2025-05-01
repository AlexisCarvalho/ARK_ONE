import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents, useMap } from 'react-leaflet';
import L from 'leaflet';
import { Button, Box, TextField, Container, Alert } from '@mui/material';
import { useLocation, useNavigate } from 'react-router-dom';
import api from '../../api';
import pokebolaIcon from '../assets/icons/alarcon.jpeg';

const customIcon = L.icon({
  iconUrl: pokebolaIcon,
  iconSize: [41, 41],
  iconAnchor: [20, 41],
  popupAnchor: [1, -34],
});

const MapComponent: React.FC = () => {
  const [position, setPosition] = useState<[number, number]>([-23.5505, -46.6333]);
  const [lat, setLat] = useState<number>(-23.5505);
  const [lng, setLng] = useState<number>(-46.6333);
  const [showAlert, setShowAlert] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();
  const { id_product_instance, id_product, esp32_unique_id } = location.state || {};

  useEffect(() => {
    if (!esp32_unique_id) return;

    const fetchLocation = async () => {
      try {
        const response = await api.get(`/Location/get_location?esp32_unique_id=${esp32_unique_id}`);
        const { status, data } = response.data;
        
        if (status[0] === 'noLocationData') {
          setShowAlert(true);
          setPosition([data.latitude[0], data.longitude[0]]);
          setLat(data.latitude[0]);
          setLng(data.longitude[0]);
        } else if (status[0] === 'success') {
          setShowAlert(false);
          setPosition([data.latitude[0], data.longitude[0]]);
          setLat(data.latitude[0]);
          setLng(data.longitude[0]);
        }
      } catch (error) {
        console.error('Erro ao buscar localização:', error);
        setShowAlert(true);
      }
    };

    fetchLocation();
  }, [esp32_unique_id]);

  const handleLatChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newLat = parseFloat(e.target.value);
    if (!isNaN(newLat)) {
      setLat(newLat);
      setPosition([newLat, lng]);
    } else {
      setLat(0);
    }
  };

  const handleLngChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newLng = parseFloat(e.target.value);
    if (!isNaN(newLng)) {
      setLng(newLng);
      setPosition([lat, newLng]);
    } else {
      setLng(0);
    }
  };

  const MapEvents = () => {
    useMapEvents({
      click(e: L.LeafletMouseEvent) {
        setPosition([e.latlng.lat, e.latlng.lng]);
        setLat(e.latlng.lat);
        setLng(e.latlng.lng);
      },
    });
    return null;
  };

  const handleVoltar = async () => {
    navigate('/specificPurchasedProduct', { state: { id_product_instance, id_product } });
  };

  const handleExportLocation = async () => {
    if (position && id_product_instance) {
      const [latitude, longitude] = position;
      try {
        await api.post('/Location/set', {
          id_product_instance,
          latitude,
          longitude,
        });
        navigate('/specificPurchasedProduct', { state: { id_product_instance, id_product } });
      } catch (error) {
        console.error('Erro ao exportar localização:', error);
        setShowAlert(true);
      }
    }
  };

  const MapRefresher = () => {
    const map = useMap();
    useEffect(() => {
      map.invalidateSize();
    }, [map]);
    return null;
  };

  return (
    <Container maxWidth="md">
      {showAlert && (
        <Alert severity="warning" sx={{ mb: 2, color: 'red' }}>
          Ainda não há nenhuma localização definida. Por favor insira no mapa
        </Alert>
      )}

      <MapContainer
        className="map-container"
        zoom={13}
        center={position}
        style={{
          height: 'calc(100vw * 9 / 16)',
          width: '100%',
          maxHeight: '500px',
          borderRadius: '8px',
          overflow: 'hidden',
        }}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        />
        <MapRefresher />
        <MapEvents />
        {position && (
          <Marker position={position} icon={customIcon}>
            <Popup>Você clicou aqui!</Popup>
          </Marker>
        )}
      </MapContainer>

      <Box
        mt={5}
        mb={5}
        sx={{
          backgroundColor: 'rgba(255, 255, 255, 0.6)',
          borderRadius: 2,
          padding: 4,
          boxShadow: 10,
          color: 'black',
          textAlign: 'center',
        }}
      >
        <TextField
          label="Latitude"
          variant="filled"
          fullWidth
          margin="normal"
          color="primary"
          value={lat}
          onChange={handleLatChange}
          sx={{
            input: { color: 'black' },
            bgcolor: 'rgba(255, 255, 255, 0.8)',
            borderRadius: 1,
          }}
        />

        <TextField
          label="Longitude"
          variant="filled"
          fullWidth
          margin="normal"
          color="primary"
          value={lng}
          onChange={handleLngChange}
          sx={{
            input: { color: 'black' },
            bgcolor: 'rgba(255, 255, 255, 0.8)',
            borderRadius: 1,
          }}
        />

        <Button
          variant="contained"
          fullWidth
          sx={{
            mt: 2,
            backgroundColor: '#28a745',
            '&:hover': { backgroundColor: '#218838' },
          }}
          onClick={handleExportLocation}
        >
          Exportar Localização
        </Button>
        <Button
          variant="contained"
          fullWidth
          sx={{
            mt: 2,
            backgroundColor: '#007bff',
            '&:hover': { backgroundColor: '#0056b3' },
          }}
          onClick={handleVoltar}
        >
          Voltar
        </Button>
      </Box>
    </Container>
  );
};

export default MapComponent;
