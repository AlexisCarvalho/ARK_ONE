import React, { useEffect, useState } from 'react';
import { Container, Typography, Box, Card, CardContent, Grid, Button } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api';

interface Product {
  id_product: number;
  product_name: string;
  product_description: string;
  location_dependent: boolean;
  product_price: number;
}

const PurchasedProducts: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const response = await api.get('Person/products_purchased');
        setProducts(response.data.data);
      } catch (error) {
        alert('Failed to retrieve products');
      }
    };
    fetchProducts();
  }, []);

  const handleBuyNew = () => {
    navigate('/'); 
  };

  const handleViewMyProducts = () => {
    navigate('/'); 
  };

  return (
    <Container maxWidth="md">
      <Box 
        textAlign="center" 
        mt={5}
        sx={{
          backgroundColor: 'rgba(0, 0, 0, 0.8)',
          borderRadius: 2,
          padding: 3,
          boxShadow: 3,
          color: 'white'
        }}
      >
        <Typography variant="h4" gutterBottom sx={{ fontWeight: 'bold' }}>
          Produtos do Ark One
        </Typography>
        <Grid container spacing={3} mt={3}>
          {products.map((product) => (
            <Grid item xs={12} sm={6} md={4} key={product.id_product}>
              <Card sx={{ bgcolor: 'white', color: 'black' }}>
                <CardContent>
                  <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                    {product.product_name}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {product.product_description}
                  </Typography>
                  <Typography variant="body1" mt={1}>
                    Preço: R$ {product.product_price.toFixed(2)}
                  </Typography>
                  <Box mt={2}>
                    <Button 
                      variant="contained" 
                      sx={{ mr: 1, backgroundColor: '#007bff', '&:hover': { backgroundColor: '#0056b3' } }} 
                      onClick={handleBuyNew}
                    >
                      Cadastrar Novo
                    </Button>
                    <Button 
                      variant="contained" 
                      sx={{ backgroundColor: '#28a745', '&:hover': { backgroundColor: '#218838' }, mt: 1 }} 
                      onClick={handleViewMyProducts}
                    >
                      Meus Produtos
                    </Button>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </Box>
    </Container>
  );
};

export default PurchasedProducts;
