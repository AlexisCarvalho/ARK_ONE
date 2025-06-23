import React, { useEffect, useState } from 'react';
import { Container, Typography, Box, Grid, Select, MenuItem, FormControl, InputLabel, Button, TextField } from '@mui/material';
import { useLocation, useNavigate } from 'react-router-dom';
import { gsap } from 'gsap';
import api from '../../api';
import MapComponent from '../maps/MapComponent';
import './SpecificPurchasedProduct.css';

interface ProductOwned {
  id_product_instance: string;
  product_name: string;
  esp32_unique_id: string;
  location_dependent: boolean;
}

interface LocationState {
  id_product: string;
}

const SpecificPurchasedProduct: React.FC = () => {
  const [productInstances, setProductInstances] = useState<ProductOwned[]>([]);
  const [selectedProduct, setSelectedProduct] = useState<ProductOwned | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [lat, setLat] = useState<number>(-22.6651);
  const [lng, setLng] = useState<number>(-45.0086);
  const [hasLocation, setHasLocation] = useState<boolean>(true);
  const location = useLocation();
  const id_product = (location.state as LocationState)?.id_product;
  const navigate = useNavigate();

  useEffect(() => {
    const fetchProductInstances = async () => {
      try {
        const response = await api.get(`Products/owned/${id_product}`);
        const products = response.data.data.products_owned;

        if (products.length === 0) {
          setError('Nenhum produto deste tipo cadastrado.');
        } else {
          setError(null);
          setProductInstances(products);
          // Auto select first product
          setSelectedProduct(products[0]);
        }
      } catch (error) {
        console.error(error);
        setError('Nenhum produto deste tipo cadastrado.');
      }
    };
    fetchProductInstances();
  }, [id_product]);

  const fetchProductLocation = async (productId: string) => {
    try {
      const response = await api.get(`/Locations/${productId}`);
      const { status, data } = response.data;
      
      if (status[0] === 'success' && data.location && data.location.length > 0) {
        const location = data.location[0];
        setLat(location.latitude);
        setLng(location.longitude);
        setHasLocation(true);
      } else {
        setLat(-22.6651); // Default location
        setLng(-45.0086); // Default location
        setHasLocation(false);
      }
    } catch (error) {
      console.error('Erro ao buscar localização:', error);
      setHasLocation(false);
    }
  };

  const handleDeleteESP32 = async () => {
    if (!selectedProduct) return;
    try {
      await api.delete(`Products/owned/${selectedProduct.esp32_unique_id}`);
      setProductInstances((prev) =>
        prev.filter((instance) => instance.esp32_unique_id !== selectedProduct.esp32_unique_id)
      );
      setSelectedProduct(productInstances[0] || null);
    } catch (error) {
      console.error('Erro ao deletar o ESP32:', error);
    }
  };

  const handleViewDataAnalysis = () => {
    if (!selectedProduct) return;
    navigate('/dashboard', {
      state: { 
        previousLocation: window.location.pathname, 
        id_product_instance: selectedProduct.id_product_instance,
        id_product,
        esp32_unique_id: selectedProduct.esp32_unique_id,
        esp32_unique_ids: productInstances.map(p => p.esp32_unique_id) // <-- Adicionado: envia todos os esp32_unique_id
      }
    });
  };

  const handleLatChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newLat = parseFloat(e.target.value);
    if (!isNaN(newLat)) setLat(newLat);
  };

  const handleLngChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newLng = parseFloat(e.target.value);
    if (!isNaN(newLng)) setLng(newLng);
  };

  const handleUpdateLocation = async () => {
    if (!selectedProduct) return;
    try {
      await api.post('/Locations/set', {
        id_product_instance: selectedProduct.id_product_instance,
        latitude: lat,
        longitude: lng,
      });
      // Refresh map by forcing a re-render
      setSelectedProduct({ ...selectedProduct });
    } catch (error) {
      console.error('Erro ao atualizar localização:', error);
    }
  };

  const handleProductChange = (event: any) => {
    const selected = productInstances.find(p => p.id_product_instance === event.target.value);
    setSelectedProduct(selected || null);
    if (selected) {
      fetchProductLocation(selected.id_product_instance);
    }
  };

  const handleMapClick = (latitude: number, longitude: number) => {
    setLat(latitude);
    setLng(longitude);
  };

  // Update initial product selection to also fetch location
  useEffect(() => {
    const fetchProductInstances = async () => {
      try {
        const response = await api.get(`Products/owned/${id_product}`);
        const products = response.data.data.products_owned;

        if (products.length === 0) {
          setError('Nenhum produto deste tipo cadastrado.');
        } else {
          setError(null);
          setProductInstances(products);
          // Auto select first product
          setSelectedProduct(products[0]);
          fetchProductLocation(products[0].id_product_instance);
        }
      } catch (error) {
        console.error(error);
        setError('Nenhum produto deste tipo cadastrado.');
      }
    };
    fetchProductInstances();
  }, [id_product]);

  useEffect(() => {
    initAnimations();
  }, []);

  const initAnimations = () => {
    // Initial setup - invisible elements
    gsap.set([".product-title", ".product-form", ".map-container"], {
      opacity: 0,
      y: 50
    });

    gsap.set(".floating-icon", {
      opacity: 0,
      scale: 0
    });

    gsap.set(".shape", {
      scale: 0,
      rotation: 45
    });

    // Animation timeline
    const tl = gsap.timeline();

    // Background shapes animation
    tl.to(".shape", {
      scale: 1,
      rotation: 0,
      duration: 1.5,
      ease: "elastic.out(1, 0.5)",
      stagger: 0.1
    });

    // Main content animation
    tl.to([".product-title", ".product-form", ".map-container"], {
      opacity: 1,
      y: 0,
      duration: 1,
      ease: "power3.out",
      stagger: 0.2
    }, "-=0.8");

    // Floating icons animation
    tl.to(".floating-icon", {
      opacity: 1,
      scale: 1,
      duration: 0.8,
      ease: "back.out(1.7)",
      stagger: 0.15
    }, "-=0.5");

    // Continuous animations
    gsap.to(".shape", {
      rotation: 360,
      duration: 20,
      repeat: -1,
      ease: "none",
      stagger: { each: 5, from: "random" }
    });

    gsap.to(".floating-icon", {
      y: -20,
      duration: 2,
      repeat: -1,
      yoyo: true,
      ease: "power2.inOut",
      stagger: 0.3
    });
  };

  return (
    <div className="specific-product-container">
      <div className="background-shapes">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
        <div className="shape shape-4"></div>
      </div>

      <div className="floating-elements">
        <div className="floating-icon icon-1">📍</div>
        <div className="floating-icon icon-2">🌍</div>
        <div className="floating-icon icon-3">📡</div>
      </div>

      <Container maxWidth="xl">
        <Grid container spacing={3} className="content-grid">
          <Grid item xs={12} md={4}>
            <Box className="product-card product-form" sx={{ p: 3, borderRadius: 2 }}>
              <Typography variant="h4" gutterBottom className="product-title" sx={{ fontWeight: 'bold' }}>
                Meus Produtos
              </Typography>

              {error ? (
                <Typography variant="body1" color="error" sx={{ mt: 2, fontWeight: 'bold' }}>
                  {error}
                </Typography>
              ) : (
                <>
                  <FormControl fullWidth sx={{ mt: 2 }}>
                    <InputLabel>Selecione um Produto</InputLabel>
                    <Select
                      value={selectedProduct?.id_product_instance || ''}
                      onChange={handleProductChange}
                      label="Selecione um Produto"
                    >
                      {productInstances.map((product) => (
                        <MenuItem key={product.id_product_instance} value={product.id_product_instance}>
                          {product.product_name} - {product.esp32_unique_id}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>

                  {selectedProduct && (
                    <Box sx={{ mt: 2, display: 'flex', gap: 1, flexDirection: 'column' }}>
                      <Button
                        variant="contained"
                        fullWidth
                        sx={{
                          backgroundColor: '#28a745',
                          '&:hover': { backgroundColor: '#218838' },
                        }}
                        onClick={handleViewDataAnalysis}
                      >
                        Ver Análise
                      </Button>
                      {selectedProduct.location_dependent && (
                        <>
                          <TextField
                            label="Latitude"
                            variant="filled"
                            fullWidth
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
                              backgroundColor: '#007bff',
                              '&:hover': { backgroundColor: '#0056b3' },
                            }}
                            onClick={handleUpdateLocation}
                          >
                            Atualizar Localização
                          </Button>
                        </>
                      )}
                      <Button
                        variant="contained"
                        fullWidth
                        color="error"
                        onClick={handleDeleteESP32}
                      >
                        Deletar ESP32
                      </Button>
                    </Box>
                  )}
                </>
              )}
            </Box>
          </Grid>
          <Grid item xs={12} md={8}>
            <Box className="product-card map-container" sx={{ p: 3, borderRadius: 2 }}>
              {!hasLocation && selectedProduct && (
                <Typography 
                  variant="subtitle1" 
                  color="warning.main" 
                  sx={{ mb: 2, fontWeight: 'bold', textAlign: 'center' }}
                >
                  Este produto ainda não possui uma localização definida. Por favor, selecione uma localização no mapa.
                </Typography>
              )}
              {selectedProduct && (
                <MapComponent
                  id_product_instance={selectedProduct.id_product_instance}
                  id_product={id_product}
                  esp32_unique_id={selectedProduct.esp32_unique_id}
                  embedded={true}
                  clickable={true}
                  onPositionChange={handleMapClick}
                  initialLat={lat}
                  initialLng={lng}
                />
              )}
            </Box>
          </Grid>
        </Grid>
      </Container>
    </div>
  );
};

export default SpecificPurchasedProduct;
