import React, { useState, useEffect } from 'react';
import { Container, TextField, Button, Typography, Box, Select, MenuItem, InputLabel, FormControl, Checkbox, FormControlLabel } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import api from '../../api';

const RegisterProduct: React.FC = () => {
  const [productName, setProductName] = useState('');
  const [productDescription, setProductDescription] = useState('');
  const [productPrice, setProductPrice] = useState('');
  const [idCategory, setIdCategory] = useState<number | ''>('');  
  const [locationDependent, setLocationDependent] = useState(false);
  const [categories, setCategories] = useState<any[]>([]);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const fetchCategories = async () => {
    try {
      const response = await api.get('/Category/get_all');
      if (response.data.status[0] === 'success') {
        setCategories(response.data.data);
      } else {
        setCategories([]);
      }
    } catch (error) {
      console.error('Erro ao buscar categorias:', error);
      setCategories([]);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!productName || !productDescription || !productPrice) {
      setError('Nome, descrição e preço são obrigatórios.');
      return;
    }

    try {
      const response = await api.post('/Products/create', {
        product_name: productName,
        product_description: productDescription,
        id_category: idCategory ? idCategory : null,
        location_dependent: locationDependent,
        product_price: productPrice,
      });

      if (response.status === 201) {
        navigate('/productList');
      } else {
        setError('Erro ao criar o produto.');
      }
    } catch (error) {
      console.error('Erro ao criar produto:', error);
      setError('Erro ao criar o produto.');
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
          Cadastrar Produto
        </Typography>

        <TextField 
          label="Nome do Produto" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={productName} 
          onChange={(e) => setProductName(e.target.value)} 
          error={!!error} 
          onFocus={() => setError('')} 
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />

        <TextField 
          label="Descrição do Produto" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={productDescription} 
          onChange={(e) => setProductDescription(e.target.value)} 
          error={!!error}
          onFocus={() => setError('')}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />

        <TextField 
          label="Preço do Produto" 
          type="number" 
          variant="filled" 
          fullWidth 
          margin="normal" 
          color="primary"
          value={productPrice} 
          onChange={(e) => setProductPrice(e.target.value)} 
          error={!!error}
          onFocus={() => setError('')}
          sx={{ 
            input: { color: 'black' }, 
            bgcolor: 'rgba(255, 255, 255, 0.8)', 
            borderRadius: 1 
          }}
        />

        <FormControl fullWidth margin="normal">
          <InputLabel id="category-label">Categoria</InputLabel>
          <Select
            labelId="category-label"
            value={idCategory}
            onChange={(e) => {
              const selectedCategory = e.target.value ? Number(e.target.value) : '';
              setIdCategory(selectedCategory);
            }}
            label="Categoria"
            color="primary"
            sx={{
              backgroundColor: 'rgba(255, 255, 255, 0.8)', 
              borderRadius: 1,
              '.MuiSelect-icon': { color: 'black' },
            }}
          >
            <MenuItem value="">
              <em>Sem Categoria</em>
            </MenuItem>
            {categories.map((category) => (
              <MenuItem key={category.id_category} value={category.id_category}>
                {category.category_name}
              </MenuItem>
            ))}
          </Select>
        </FormControl>

        <FormControlLabel
          control={
            <Checkbox
              checked={locationDependent}
              onChange={(e) => setLocationDependent(e.target.checked)}
              name="locationDependent"
              color="primary"
            />
          }
          label="Produto Dependente de Localização"
          sx={{ color: 'black', marginTop: 2 }}
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
            '&:hover': { backgroundColor: '#0056b3' } 
          }} 
          onClick={handleSubmit}
        >
          Cadastrar Produto
        </Button>
      </Box>
    </Container>
  );
};

export default RegisterProduct;
