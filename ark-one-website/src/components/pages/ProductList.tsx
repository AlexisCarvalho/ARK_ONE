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

const ProductList: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [isAdmin, setIsAdmin] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchUserType = async () => {
      try {
        const response = await api.get('/Person/getType');
        if (response.data.status[0] === 'success' && response.data.data[0] === 'admin') {
          setIsAdmin(true);
        }
      } catch (error) {
        console.error('Erro ao verificar tipo de usuário:', error);
      }
    };

    const fetchProducts = async () => {
      try {
        const response = await api.get('/Products/get_all');
        
        if (response.status === 204) {
          setErrorMessage('Lamentamos informar que não temos produtos disponíveis');
        } else {
          setProducts(response.data.data);
          setErrorMessage(null);
        }
      } catch (error) {
        setErrorMessage('Erro ao recuperar produtos. Tente novamente mais tarde.');
      }
    };

    fetchUserType();
    fetchProducts();
  }, []);

  const handleRegisterNewESP32 = (id_product: number) => {
    navigate('/RegisterESP32', { state: { previousLocation: window.location.pathname, id_product } });
  };

  const handleViewMyProducts = (id_product: number) => {
    navigate('/specificPurchasedProduct', { state: { previousLocation: window.location.pathname, id_product } });
  };

  const handleDeleteProduct = async (id_product: number) => {
    try {
      await api.delete(`/Products/delete_product?id_product=${id_product}`);
      setProducts(products.filter((product) => product.id_product !== id_product));
    } catch (error) {
      console.error('Erro ao deletar produto:', error);
      alert('Erro ao deletar o produto. Tente novamente mais tarde.');
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
          Produtos do Ark One
        </Typography>

        {errorMessage ? (
          <Typography variant="body1" color="error" mt={3}>
            {errorMessage}
          </Typography>
        ) : (
          <Grid container spacing={3} mt={3}>
            {products.map((product) => (
              <Grid item xs={12} sm={6} md={4} key={product.id_product}>
                <Card sx={{ bgcolor: 'white', color: 'black', boxShadow: 10, borderRadius: 5 }}>
                  <CardContent>
                    <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                      {product.product_name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      {product.product_description}
                    </Typography>
                    <Typography variant="body1" mt={1}>
                      Preço: R$ {product.product_price ? product.product_price.toFixed(2) : 'N/A'}
                    </Typography>
                    <Box mt={2}>
                      <Button
                        variant="contained"
                        sx={{ mr: 1, backgroundColor: '#007bff', '&:hover': { backgroundColor: '#0056b3' } }}
                        onClick={() => handleRegisterNewESP32(product.id_product)}
                      >
                        Cadastrar Novo
                      </Button>
                      <Button
                        variant="contained"
                        sx={{ backgroundColor: '#28a745', '&:hover': { backgroundColor: '#218838' }, mt: 1 }}
                        onClick={() => handleViewMyProducts(product.id_product)}
                      >
                        Meus Produtos
                      </Button>
                      {isAdmin && (
                        <Button
                          variant="contained"
                          color="error"
                          sx={{ mt: 1 }}
                          onClick={() => handleDeleteProduct(product.id_product)}
                        >
                          Deletar Produto
                        </Button>
                      )}
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

export default ProductList;
