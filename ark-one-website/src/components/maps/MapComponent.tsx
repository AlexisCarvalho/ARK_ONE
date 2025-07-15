import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents, useMap } from 'react-leaflet';
import L from 'leaflet';
import { Button, Box, TextField, Container, Alert } from '@mui/material';
import { useLocation, useNavigate } from 'react-router-dom';
import api from '../../api';
import pingIcon from '../../assets/icons/solarTrackerPingIcon.png';

const customIcon = L.icon({
  iconUrl: pingIcon,
  iconSize: [41, 60.6],
  iconAnchor: [20, 60.6],
  popupAnchor: [1, -34],
});

interface MapComponentProps {
  id_product_instance: string;
  id_product: string;
  esp32_unique_id: string;
  embedded?: boolean;
  clickable?: boolean;
  onPositionChange?: (latitude: number, longitude: number) => void;
  initialLat?: number;
  initialLng?: number;
}

const MapComponent: React.FC<MapComponentProps> = ({ 
  id_product_instance: propId,
  embedded = false,
  clickable = false,
  onPositionChange,
  initialLat,
  initialLng
}) => {
  const [position, setPosition] = useState<[number, number]>(
    initialLat && initialLng ? [initialLat, initialLng] : [-22.6651, -45.0086]
  );
  const [lat, setLat] = useState<number>(-22.6651);
  const [lng, setLng] = useState<number>(-45.0086);
  const [showAlert, setShowAlert] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();
  const { id_product_instance, id_product, esp32_unique_id } = location.state || {};

  useEffect(() => {
    if (!id_product_instance) return;

    const fetchLocation = async () => {
      try {
        const response = await api.get(`/Locations/${id_product_instance}`);
        const { status, data } = response.data;

        if (status[0] === 'not_found') {
          setShowAlert(true);
        } else if (status[0] === 'success') {
          setShowAlert(false);
          const location = data.location[0];
          setPosition([location.latitude, location.longitude]);
          setLat(location.latitude);
          setLng(location.longitude);
        }
      } catch (error) {
        console.error('Erro ao buscar localização:', error);
        setShowAlert(true);
      }
    };

    fetchLocation();
  }, [id_product_instance]);

  useEffect(() => {
    if (initialLat && initialLng) {
      setPosition([initialLat, initialLng]);
    }
  }, [initialLat, initialLng]);

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
        if (clickable && onPositionChange) {
          setPosition([e.latlng.lat, e.latlng.lng]);
          onPositionChange(e.latlng.lat, e.latlng.lng);
        }
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
        await api.post('/Locations/set', {
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
      if (position) {
        map.setView(position, map.getZoom());
      }
    }, [position, map]);
    return null;
  };

  const mapContent = (
    <>
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
        {clickable && <MapEvents />}
        {position && (
          <Marker position={position} icon={customIcon}>
            <Popup>{clickable ? 'Localização selecionada' : 'Localização atual'}</Popup>
          </Marker>
        )}
      </MapContainer>

      {!embedded && (
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
      )}
    </>
  );

  return embedded ? mapContent : <Box maxWidth="md" sx={{ mx: 'auto' }}>{mapContent}</Box>;
};

export default MapComponent;
