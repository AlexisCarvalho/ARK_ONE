import React, { useEffect, useState } from 'react';
import { Container, Typography, Box, Card, CardContent, Grid, Button } from '@mui/material';
import { useNavigate, useLocation } from 'react-router-dom';
import api from '../../api';

interface ProductOwned {
  id_product_instance: number;
  product_name: string;
  esp32_unique_id: string;
  location_dependent: boolean;
}

interface LocationState {
  id_product: number;
}

const SpecificPurchasedProduct: React.FC = () => {
  const [productInstances, setProductInstances] = useState<ProductOwned[]>([]);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const location = useLocation();
  const id_product = (location.state as LocationState)?.id_product;

  useEffect(() => {
    const fetchProductInstances = async () => {
      try {
        const response = await api.get(`Products/owned/${id_product}`);

        if (response.data.data.products_owned.length === 0) {
          setError('Nenhum produto deste tipo cadastrado.');
        } else {
          setError(null);
        }

        setProductInstances(response.data.data.products_owned);
      } catch (error) {
        console.error(error);
        setError('Erro ao carregar os produtos');
      }
    };
    fetchProductInstances();
  }, [id_product]);

  const handleSetLocation = (id_product_instance: number, esp32_unique_id: string) => {
    navigate('/setLocationMap', {
      state: { 
        previousLocation: window.location.pathname, 
        id_product_instance, 
        id_product, 
        esp32_unique_id 
      }
    });
  };

  const handleViewDataAnalysis = (id_product_instance: number, esp32_unique_id: string) => {
    navigate('/dashboard', {
      state: { 
        previousLocation: window.location.pathname, 
        id_product_instance,
        id_product,
        esp32_unique_id
      }
    });
  };

  const handleDeleteESP32 = async (esp32_unique_id: string) => {
    try {
      await api.delete(`Products/owned/${esp32_unique_id}`);
      setProductInstances((prev) =>
        prev.filter((instance) => instance.esp32_unique_id !== esp32_unique_id)
      );
    } catch (error) {
      console.error('Erro ao deletar o ESP32:', error);
      setError('Erro ao deletar o ESP32');
    }
  };

  return (
    <Container maxWidth="md">
      <Box
        textAlign="center"
        mt={5}
        sx={{
          backgroundColor: 'rgba(255, 255, 255, 0.8)',
          borderRadius: 2,
          padding: 3,
          boxShadow: 10,
          color: 'black',
        }}
      >
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
          Meus Produtos
        </Typography>

        {error ? (
          <Typography variant="body1" color="error" sx={{ mt: 2, fontWeight: 'bold' }}>
            {error}
          </Typography>
        ) : (
          <Grid container spacing={3} mt={3}>
            {productInstances.map((productInstance) => (
              <Grid item xs={12} sm={6} md={4} key={productInstance.id_product_instance}>
                <Card sx={{ bgcolor: 'white', color: 'black', boxShadow: 10, borderRadius: 5 }}>
                  <CardContent>
                    <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                      {productInstance.product_name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      ESP32 ID: {productInstance.esp32_unique_id}
                    </Typography>
                    {productInstance.location_dependent && (
                      <Box mt={2}>
                        <Button
                          variant="contained"
                          sx={{
                            mr: 1,
                            backgroundColor: '#007bff',
                            '&:hover': { backgroundColor: '#0056b3' },
                          }}
                          onClick={() =>
                            handleSetLocation(productInstance.id_product_instance, productInstance.esp32_unique_id)
                          }
                        >
                          Definir Localização
                        </Button>
                      </Box>
                    )}
                    <Box mt={2}>
                      <Button
                        variant="contained"
                        sx={{
                          backgroundColor: '#28a745',
                          '&:hover': { backgroundColor: '#218838' },
                        }}
                        onClick={() => handleViewDataAnalysis(productInstance.id_product_instance, productInstance.esp32_unique_id)}
                      >
                        Ver Análise
                      </Button>
                    </Box>
                    <Box mt={2}>
                      <Button
                        variant="contained"
                        color="error"
                        onClick={() => handleDeleteESP32(productInstance.esp32_unique_id)}
                      >
                        Deletar ESP32
                      </Button>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Box>
    </Container>
  );
};

export default SpecificPurchasedProduct;
