import React, { useEffect, useState } from 'react';
import { Container, Typography, Box, Grid, Select, MenuItem, FormControl, InputLabel, Button, TextField, Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions } from '@mui/material';
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
  const [isAdmin, setIsAdmin] = useState<boolean>(false);
  const [isModerator, setIsModerator] = useState<boolean>(false);
  const location = useLocation();
  const id_product = (location.state as LocationState)?.id_product;
  const navigate = useNavigate();

  useEffect(() => {
    fetchUserType();
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

  // Delete confirmation dialog state
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deletingESP32, setDeletingESP32] = useState<string | null>(null);

  // Open confirmation dialog
  const handleDeleteESP32 = () => {
    if (!selectedProduct) return;
    setDeletingESP32(selectedProduct.esp32_unique_id);
    setOpenDeleteDialog(true);
  };

  // Perform deletion after confirmation
  const performDeleteESP32 = async () => {
    if (!deletingESP32) return;
    setDeleteLoading(true);
    try {
      await api.delete(`Products/owned/${deletingESP32}`);
      // Update local list and auto-select the first remaining device
      const updatedList = productInstances.filter((instance) => instance.esp32_unique_id !== deletingESP32);
      setProductInstances(updatedList);
      const first = updatedList[0] || null;
      setSelectedProduct(first);
      if (first) {
        // fetch its location to update map/message
        fetchProductLocation(first.id_product_instance);
      } else {
        // no devices left, reset location flag
        setHasLocation(false);
      }
      setOpenDeleteDialog(false);
      setDeletingESP32(null);
    } catch (error) {
      console.error('Erro ao deletar o ESP32:', error);
    } finally {
      setDeleteLoading(false);
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
      // Remove the "no location" message after a successful update
      setHasLocation(true);
      // Re-fetch location from server to ensure coordinates are in sync
      fetchProductLocation(selectedProduct.id_product_instance);
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

  const fetchUserType = async () => {
    try {
      const response = await api.get('/Users/role');
      if (
        response.data.status[0] === 'success' &&
        response.data.data[0].user_role === 'admin'
      ) {
        setIsAdmin(true);
      } else if (
        response.data.status[0] === 'success' &&
        response.data.data[0].user_role === 'moderator'
      ) {
        setIsModerator(true);
      }
    } catch (error) {
      console.error('Erro ao verificar tipo de usuário:', error);
    }
  };

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
                              '&.Mui-disabled': { backgroundColor: '#e0e0e0', color: '#9e9e9e' }
                            }}
                            onClick={handleUpdateLocation}
                            disabled={!(isAdmin || isModerator)}
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
                        disabled={!(isAdmin || isModerator)}
                        sx={{ '&.Mui-disabled': { backgroundColor: '#e0e0e0', color: '#9e9e9e' } }}
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

      {/* Delete confirmation dialog */}
      <Dialog open={openDeleteDialog} onClose={() => setOpenDeleteDialog(false)}>
        <DialogTitle>Confirmar Exclusão</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Tem certeza que deseja deletar o ESP32 {deletingESP32}? Esta ação não pode ser desfeita.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ pr: 3, pb: 2 }}>
          <Button onClick={() => setOpenDeleteDialog(false)} disabled={deleteLoading}>Cancelar</Button>
          <Button color="error" variant="contained" onClick={performDeleteESP32} disabled={deleteLoading}>
            {deleteLoading ? 'Deletando...' : 'Deletar ESP32'}
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default SpecificPurchasedProduct;
